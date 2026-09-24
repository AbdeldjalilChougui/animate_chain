import 'dart:async';

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import 'adapters.dart';
import 'effect.dart';

/// Signature of [Animate] lifecycle callbacks.
typedef AnimateCallback = void Function(AnimationController controller);

/// Applies a chain of [Effect]s to [child], driven by one
/// [AnimationController].
///
/// ```dart
/// // chained
/// Text('Hi').animate().fadeIn().slideY().then(delay: 100.ms).shake();
///
/// // declarative
/// Animate(effects: const [FadeEffect(), ScaleEffect()], child: Text('Hi'));
/// ```
///
/// Effects run in parallel. Each one may set `delay`, `duration` and `curve`;
/// omitted values are inherited from the previous effect (the first effect
/// falls back to [defaultDuration] and [defaultCurve]). Use `then()` to start
/// the following effects when the previous one ends.
///
/// Every chain call returns a new, immutable [Animate].
///
/// Lifecycle:
/// * The animation is restarted only when [key] changes, when the timing
///   of the chain changes (effect types, delays or durations) or when
///   [controller] changes. Changing only effect values (such as `begin`,
///   `end`, colours or builders) updates the output in place.
/// * When [target] is set, changes to it animate smoothly from the current
///   position. [delay] applies to each change, and a newer change cancels
///   a pending one.
/// * When the platform asks for reduced motion
///   ([MediaQueryData.disableAnimations]) and [respectReducedMotion] allows
///   it, the animation jumps to its end state (or [target]) without delay.
class Animate extends StatefulWidget with EffectChain<Animate> {
  /// Creates an [Animate] that applies [effects] to [child].
  Animate({
    super.key,
    this.child = const SizedBox.shrink(),
    List<Effect<Object?>>? effects,
    this.onInit,
    this.onPlay,
    this.onComplete,
    this.autoPlay = true,
    this.delay = Duration.zero,
    this.controller,
    this.adapter,
    this.target,
    this.value,
    this.respectReducedMotion,
  })  : assert(target == null || (target >= 0 && target <= 1)),
        assert(value == null || (value >= 0 && value <= 1)),
        effects = List.unmodifiable(effects ?? const <Effect<Object?>>[]);

  /// Duration used by the first effect when it sets none.
  static Duration defaultDuration = const Duration(milliseconds: 300);

  /// Curve used by the first effect when it sets none.
  static Curve defaultCurve = Curves.linear;

  /// When true, every [Animate] restarts on hot reload. Handy while tuning.
  static bool restartOnHotReload = false;

  /// Global default for [respectReducedMotion]; `true` unless changed.
  static bool defaultRespectReducedMotion = true;

  /// The widget the effects are applied to.
  final Widget child;

  /// The effects, in chain order.
  final List<Effect<Object?>> effects;

  /// Called once with the internal controller right after it is created
  /// (not called when an external [controller] is supplied).
  final AnimateCallback? onInit;

  /// Called when playback starts (after [delay]). Not called when
  /// [autoPlay] is false, when a [target] or [adapter] drives the animation,
  /// or when reduced motion skips the animation.
  final AnimateCallback? onPlay;

  /// Called once each time the animation completes.
  final AnimateCallback? onComplete;

  /// Whether to play automatically on mount. With a [target], `false`
  /// jumps to the initial target instead of animating to it.
  final bool autoPlay;

  /// Wait before playing. With a [target], applies to every target change.
  final Duration delay;

  /// Optional external controller. Its duration is set to [duration].
  /// Otherwise a single internal controller is created and disposed.
  final AnimationController? controller;

  /// Optional [Adapter] that drives the animation from an outside source.
  /// While set, the animation does not play by itself.
  final Adapter? adapter;

  /// State-driven position, 0 (start) to 1 (end). Changes animate smoothly.
  final double? target;

  /// Initial position, 0 to 1. Changing it jumps to the new position.
  final double? value;

  /// Whether reduced motion skips the animation for this widget.
  /// `null` uses [Animate.defaultRespectReducedMotion].
  final bool? respectReducedMotion;

  late final (List<EffectEntry>, Duration) _timeline = _resolve();

  /// Resolved timing of every effect, in chain order.
  List<EffectEntry> get entries => _timeline.$1;

  /// Total duration: the latest end of any effect.
  Duration get duration => _timeline.$2;

  (List<EffectEntry>, Duration) _resolve() {
    final timings = <(Effect<Object?>, Duration, Duration, Curve)>[];
    var base = Duration.zero;
    var total = Duration.zero;
    (Effect<Object?>, Duration, Duration, Curve)? prior;
    for (final effect in effects) {
      final Duration start;
      if (effect is ThenEffect) {
        base = (prior == null ? Duration.zero : prior.$2 + prior.$3) +
            (effect.delay ?? Duration.zero);
        start = base;
      } else if (effect.delay != null) {
        start = base + effect.delay!;
      } else {
        start = prior?.$2 ?? base;
      }
      final length = effect.duration ?? prior?.$3 ?? defaultDuration;
      final curve = effect.curve ?? prior?.$4 ?? defaultCurve;
      final timing = (effect, start, length, curve);
      timings.add(timing);
      prior = timing;
      if (effect is! ThenEffect && start + length > total) {
        total = start + length;
      }
    }
    return (
      List.unmodifiable([
        for (final t in timings)
          EffectEntry(
            effect: t.$1,
            delay: t.$2,
            duration: t.$3,
            curve: t.$4,
            total: total,
            owner: this,
          ),
      ]),
      total,
    );
  }

  @override
  Animate addEffect(Effect<Object?> effect) => Animate(
        key: key,
        effects: [...effects, effect],
        onInit: onInit,
        onPlay: onPlay,
        onComplete: onComplete,
        autoPlay: autoPlay,
        delay: delay,
        controller: controller,
        adapter: adapter,
        target: target,
        value: value,
        respectReducedMotion: respectReducedMotion,
        child: child,
      );

  @override
  State<Animate> createState() => _AnimateState();
}

bool _sameTiming(Animate a, Animate b) {
  if (a.duration != b.duration) return false;
  final ea = a.entries, eb = b.entries;
  if (ea.length != eb.length) return false;
  for (var i = 0; i < ea.length; i++) {
    if (ea[i].effect.runtimeType != eb[i].effect.runtimeType ||
        ea[i].delay != eb[i].delay ||
        ea[i].duration != eb[i].duration) {
      return false;
    }
  }
  return true;
}

class _AnimateState extends State<Animate> with SingleTickerProviderStateMixin {
  AnimationController? _internal;
  late AnimationController _controller;
  Adapter? _adapter;
  Timer? _timer;
  bool _started = false;
  bool _reduced = false;
  int _lifecycleDepth = 0;
  bool _holdComplete = false;
  bool _pendingComplete = false;

  // ---- lifecycle -------------------------------------------------------

  @override
  void initState() {
    super.initState();
    _inLifecycle(() {
      final created = widget.controller == null && _internal == null;
      _bindController();
      if (widget.value != null) _controller.value = widget.value!;
      if (created) widget.onInit?.call(_controller);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _inLifecycle(() {
      if (!_started) {
        _started = true;
        _reduced = _computeReduced();
        _start();
      } else {
        _syncReduced();
      }
    });
  }

  @override
  void didUpdateWidget(Animate oldWidget) {
    super.didUpdateWidget(oldWidget);
    _inLifecycle(() {
      final controllerChanged = oldWidget.controller != widget.controller;
      if (controllerChanged) {
        _detachAdapter();
        _controller.removeStatusListener(_onStatus);
        _bindController();
        if (widget.value != null) _controller.value = widget.value!;
      } else {
        _controller.duration = widget.duration;
      }
      _syncReduced();

      if (controllerChanged || oldWidget.adapter != widget.adapter) {
        _detachAdapter();
        if (widget.adapter != null) {
          _cancelTimer();
          _attachAdapter();
        }
      }
      if (_adapter != null) return;

      if (controllerChanged || !_sameTiming(oldWidget, widget)) {
        _restart();
      } else if (widget.target != oldWidget.target) {
        _goToTarget();
      } else if (widget.value != oldWidget.value && widget.value != null) {
        _controller.value = widget.value!;
      }
    });
  }

  @override
  void reassemble() {
    super.reassemble();
    if (Animate.restartOnHotReload) _inLifecycle(_restart);
  }

  @override
  void dispose() {
    _cancelTimer();
    _detachAdapter();
    _controller.removeStatusListener(_onStatus);
    _internal?.dispose();
    super.dispose();
  }

  // ---- controller & adapter -------------------------------------------

  void _bindController() {
    final controller =
        widget.controller ?? (_internal ??= AnimationController(vsync: this));
    controller.duration = widget.duration;
    controller.addStatusListener(_onStatus);
    _controller = controller;
  }

  void _attachAdapter() {
    _adapter = widget.adapter?..attach(_controller);
  }

  void _detachAdapter() {
    _adapter?.detach();
    _adapter = null;
  }

  void _syncReduced() {
    final reduced = _computeReduced();
    if (reduced == _reduced) return;
    _reduced = reduced;
    if (reduced && _adapter == null) _finishNow();
  }

  bool _computeReduced() {
    final respect =
        widget.respectReducedMotion ?? Animate.defaultRespectReducedMotion;
    return respect && (MediaQuery.maybeDisableAnimationsOf(context) ?? false);
  }

  // ---- playback --------------------------------------------------------

  void _start() {
    _cancelTimer();
    if (widget.adapter != null) {
      _attachAdapter();
      return;
    }
    if (_reduced) {
      _finishNow();
      return;
    }
    final target = widget.target;
    if (target != null) {
      if (widget.autoPlay) {
        _schedule(() => _controller.animateTo(target));
      } else {
        _controller.value = target;
      }
    } else if (widget.autoPlay) {
      _schedule(_play);
    }
  }

  void _restart() {
    _cancelTimer();
    if (_adapter != null) return;
    if (!_reduced && widget.target == null && widget.autoPlay) {
      _controller
        ..stop()
        ..value = widget.value ?? 0;
    }
    _start();
  }

  void _goToTarget() {
    _cancelTimer();
    final target = widget.target;
    if (target == null) return;
    if (_reduced) {
      _controller
        ..stop()
        ..value = target;
    } else {
      _schedule(() => _controller.animateTo(target));
    }
  }

  void _finishNow() {
    _cancelTimer();
    _controller
      ..stop()
      ..value = widget.target ?? 1;
  }

  void _play() {
    _holdComplete = true;
    _controller.forward(from: widget.value ?? 0);
    _dispatch(widget.onPlay);
    _holdComplete = false;
    if (_pendingComplete) {
      _pendingComplete = false;
      _dispatch(widget.onComplete);
    }
  }

  void _schedule(VoidCallback action) {
    _cancelTimer();
    if (widget.delay <= Duration.zero) {
      action();
    } else {
      _timer = Timer(widget.delay, () {
        _timer = null;
        if (mounted) action();
      });
    }
  }

  void _cancelTimer() {
    _timer?.cancel();
    _timer = null;
  }

  // ---- callbacks -------------------------------------------------------

  void _onStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed) return;
    if (_holdComplete) {
      _pendingComplete = true;
    } else {
      _dispatch(widget.onComplete);
    }
  }

  /// Runs [body] while marking that user callbacks must be deferred:
  /// calling them from initState/didUpdateWidget would let them trigger
  /// setState during a build.
  void _inLifecycle(VoidCallback body) {
    _lifecycleDepth++;
    try {
      body();
    } finally {
      _lifecycleDepth--;
    }
  }

  void _dispatch(AnimateCallback? callback) {
    if (callback == null) return;
    if (_lifecycleDepth == 0) {
      callback(_controller);
      return;
    }
    final controller = _controller;
    SchedulerBinding.instance
      ..addPostFrameCallback((_) {
        if (mounted) callback(controller);
      })
      ..ensureVisualUpdate();
  }

  @override
  Widget build(BuildContext context) {
    var child = widget.child;
    for (final entry in widget.entries) {
      child = entry.effect.build(context, child, _controller, entry);
    }
    return child;
  }
}

/// Adds `animate()` to every widget.
extension AnimateWidgetExtensions on Widget {
  /// Wraps this widget in an [Animate] so effects can be chained:
  /// `myWidget.animate().fadeIn().scale()`.
  Animate animate({
    Key? key,
    List<Effect<Object?>>? effects,
    AnimateCallback? onInit,
    AnimateCallback? onPlay,
    AnimateCallback? onComplete,
    bool autoPlay = true,
    Duration delay = Duration.zero,
    AnimationController? controller,
    Adapter? adapter,
    double? target,
    double? value,
    bool? respectReducedMotion,
  }) =>
      Animate(
        key: key,
        effects: effects,
        onInit: onInit,
        onPlay: onPlay,
        onComplete: onComplete,
        autoPlay: autoPlay,
        delay: delay,
        controller: controller,
        adapter: adapter,
        target: target,
        value: value,
        respectReducedMotion: respectReducedMotion,
        child: this,
      );
}
