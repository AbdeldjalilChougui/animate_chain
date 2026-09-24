import 'package:flutter/widgets.dart';

/// Drives an [Animate]'s controller from an outside source (a scroll
/// position, a slider value, ...), instead of time.
///
/// While an adapter is attached the animation does not play by itself.
/// An adapter instance can be attached to one [Animate] at a time; it is
/// detached automatically when the [Animate] is disposed or its adapter
/// changes.
///
/// Subclasses implement [attach] / [detach] and call [updateValue].
abstract class Adapter {
  /// Creates an adapter. When [animated] is true, value changes animate
  /// (over the proportional part of the animation's duration) instead of
  /// jumping.
  Adapter({this.animated = false});

  /// Whether value changes animate instead of jumping.
  final bool animated;

  AnimationController? _controller;

  /// The controller currently attached, if any.
  AnimationController? get controller => _controller;

  /// Associates this adapter with [controller] and syncs its value.
  @mustCallSuper
  void attach(AnimationController controller) {
    assert(_controller == null, 'This adapter is already attached.');
    _controller = controller;
  }

  /// Releases the controller and any listeners.
  @mustCallSuper
  void detach() {
    _controller = null;
  }

  /// Moves the controller to [value], clamped to 0-1. Ignored while detached.
  @protected
  void updateValue(double value, {bool? animate}) {
    final controller = _controller;
    if (controller == null || value.isNaN) return;
    final v = value.clamp(0.0, 1.0);
    if (animate ?? animated) {
      if (v != controller.value) controller.animateTo(v);
    } else {
      controller.value = v;
    }
  }
}

/// Drives the animation from a `ValueNotifier<double>` holding 0-1.
class ValueNotifierAdapter extends Adapter {
  /// Creates an adapter that follows [notifier].
  ValueNotifierAdapter(this.notifier, {super.animated});

  /// The source of the 0-1 value.
  final ValueNotifier<double> notifier;

  void _onChange() => updateValue(notifier.value);

  @override
  void attach(AnimationController controller) {
    super.attach(controller);
    updateValue(notifier.value, animate: false);
    notifier.addListener(_onChange);
  }

  @override
  void detach() {
    notifier.removeListener(_onChange);
    super.detach();
  }
}

/// Drives the animation from any [ChangeNotifier], reading the 0-1 value
/// with [valueGetter] each time it notifies.
class ChangeNotifierAdapter extends Adapter {
  /// Creates an adapter that follows [notifier].
  ChangeNotifierAdapter(this.notifier, this.valueGetter, {super.animated});

  /// Notifies when the value may have changed.
  final ChangeNotifier notifier;

  /// Returns the current 0-1 value.
  final ValueGetter<double> valueGetter;

  void _onChange() => updateValue(valueGetter());

  @override
  void attach(AnimationController controller) {
    super.attach(controller);
    updateValue(valueGetter(), animate: false);
    notifier.addListener(_onChange);
  }

  @override
  void detach() {
    notifier.removeListener(_onChange);
    super.detach();
  }
}

/// Drives the animation from a [ScrollController]'s offset.
///
/// Progress is 0 at [begin] pixels and 1 at [end] pixels; they default to
/// the scroll extent's minimum and maximum. Scroll positions that are not
/// laid out yet are ignored, so it is safe to attach before the scrollable
/// is built and after it is gone.
class ScrollAdapter extends Adapter {
  /// Creates an adapter that follows [scrollController].
  ScrollAdapter(this.scrollController, {this.begin, this.end, super.animated});

  /// The scroll controller whose single position is read.
  final ScrollController scrollController;

  /// Scroll offset in pixels mapped to 0. Defaults to the minimum extent.
  final double? begin;

  /// Scroll offset in pixels mapped to 1. Defaults to the maximum extent.
  final double? end;

  double? _progress() {
    if (!scrollController.hasClients) return null;
    if (scrollController.positions.length != 1) return null;
    final pos = scrollController.position;
    if (!pos.hasContentDimensions || !pos.hasPixels) return null;
    final from = begin ?? pos.minScrollExtent;
    final to = end ?? pos.maxScrollExtent;
    if (to == from) return pos.pixels >= to ? 1 : 0;
    return (pos.pixels - from) / (to - from);
  }

  void _onScroll() {
    final p = _progress();
    if (p != null) updateValue(p);
  }

  @override
  void attach(AnimationController controller) {
    super.attach(controller);
    final p = _progress();
    if (p != null) updateValue(p, animate: false);
    scrollController.addListener(_onScroll);
  }

  @override
  void detach() {
    scrollController.removeListener(_onScroll);
    super.detach();
  }
}
