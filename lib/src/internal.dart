import 'package:flutter/widgets.dart';

import 'effect.dart';

/// Curved progress of one [EffectEntry], computed on read from [parent].
///
/// It forwards listener registration to [parent] and owns no state, so it
/// never needs disposing (unlike a `CurvedAnimation`).
class EntryAnimation extends Animation<double>
    with AnimationWithParentMixin<double> {
  /// Creates a view of [entry]'s progress on [parent].
  EntryAnimation(this.parent, this.entry);

  @override
  final Animation<double> parent;

  /// The entry whose interval and curve are applied.
  final EffectEntry entry;

  @override
  double get value => entry.progress(parent.value);
}

/// Rebuilds [builder] only when `controller.value >= threshold` flips.
class ThresholdBuilder extends StatefulWidget {
  /// Creates a threshold builder.
  const ThresholdBuilder({
    super.key,
    required this.animation,
    required this.threshold,
    required this.builder,
  });

  /// The animation that is watched.
  final Animation<double> animation;

  /// The value at (and after) which [builder] receives `true`.
  final double threshold;

  /// Builds the child; `passed` is true once [threshold] is reached.
  final Widget Function(BuildContext context, bool passed) builder;

  @override
  State<ThresholdBuilder> createState() => _ThresholdBuilderState();
}

class _ThresholdBuilderState extends State<ThresholdBuilder> {
  late bool _passed;

  bool _compute() => widget.animation.value >= widget.threshold;

  @override
  void initState() {
    super.initState();
    _passed = _compute();
    widget.animation.addListener(_tick);
  }

  @override
  void didUpdateWidget(ThresholdBuilder oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.animation != widget.animation) {
      oldWidget.animation.removeListener(_tick);
      widget.animation.addListener(_tick);
    }
    _passed = _compute();
  }

  @override
  void dispose() {
    widget.animation.removeListener(_tick);
    super.dispose();
  }

  void _tick() {
    final passed = _compute();
    if (passed != _passed) setState(() => _passed = passed);
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _passed);
}

/// Calls [onTick] on every value change of [animation] while mounted, and
/// removes its listener when disposed. Renders [child] unchanged.
class AnimationTicker extends StatefulWidget {
  /// Creates a listener widget.
  const AnimationTicker({
    super.key,
    required this.animation,
    required this.onTick,
    required this.child,
  });

  /// The animation to listen to.
  final Animation<double> animation;

  /// Called with the previous and current value after every change.
  final void Function(double previous, double current) onTick;

  /// The widget below this one.
  final Widget child;

  @override
  State<AnimationTicker> createState() => _AnimationTickerState();
}

class _AnimationTickerState extends State<AnimationTicker> {
  late double _previous;

  @override
  void initState() {
    super.initState();
    _previous = widget.animation.value;
    widget.animation.addListener(_tick);
  }

  @override
  void didUpdateWidget(AnimationTicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.animation != widget.animation) {
      oldWidget.animation.removeListener(_tick);
      widget.animation.addListener(_tick);
      _previous = widget.animation.value;
    }
  }

  @override
  void dispose() {
    widget.animation.removeListener(_tick);
    super.dispose();
  }

  void _tick() {
    final current = widget.animation.value;
    final previous = _previous;
    _previous = current;
    widget.onTick(previous, current);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
