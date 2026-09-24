import 'dart:ui' show lerpDouble;

import 'package:flutter/widgets.dart';

import '../effect.dart';

/// Builds a widget from the effect's current value.
typedef CustomEffectBuilder = Widget Function(
  BuildContext context,
  double value,
  Widget child,
);

/// A one-off effect: [builder] receives the value tweened from [begin]
/// (default 0) to [end] (default 1) on every frame, plus the child.
///
/// The child is built once and passed through, so only [builder]'s own
/// widgets rebuild.
@immutable
class CustomEffect extends Effect<double> {
  /// Creates a custom effect.
  const CustomEffect({
    super.delay,
    super.duration,
    super.curve,
    double? begin,
    double? end,
    required this.builder,
  }) : super(begin: begin ?? 0.0, end: end ?? 1.0);

  /// Builds the output for the current value.
  final CustomEffectBuilder builder;

  @override
  Widget build(
    BuildContext context,
    Widget child,
    AnimationController controller,
    EffectEntry entry,
  ) {
    final progress = entry.animate(controller);
    return AnimatedBuilder(
      animation: progress,
      child: child,
      builder: (context, child) =>
          builder(context, lerpDouble(begin, end, progress.value)!, child!),
    );
  }
}

/// Adds `custom()` to chains.
extension CustomEffectExtensions<T extends EffectChain<T>> on T {
  /// Adds a [CustomEffect].
  T custom({
    required CustomEffectBuilder builder,
    Duration? delay,
    Duration? duration,
    Curve? curve,
    double? begin,
    double? end,
  }) =>
      addEffect(
        CustomEffect(
          builder: builder,
          delay: delay,
          duration: duration,
          curve: curve,
          begin: begin,
          end: end,
        ),
      );
}
