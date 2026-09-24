import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../effect.dart';

/// Flips in 3D around the horizontal or vertical axis, in turns
/// (0.5 = 180 degrees), via [Transform].
///
/// [direction] `Axis.vertical` (the default) rotates about the x axis (the
/// top tips toward the viewer); `Axis.horizontal` rotates about the y axis.
/// Defaults: `begin` -0.5 and `end` 0. If only `end` is given, `begin` is 0.
@immutable
class FlipEffect extends Effect<double> {
  /// Creates a flip effect.
  const FlipEffect({
    super.delay,
    super.duration,
    super.curve,
    double? begin,
    double? end,
    this.direction = Axis.vertical,
    this.perspective = 1,
    this.alignment = Alignment.center,
  }) : super(begin: begin ?? (end == null ? -0.5 : 0.0), end: end ?? 0.0);

  /// Which way the child flips (see class docs).
  final Axis direction;

  /// Strength of the 3D perspective. 0 gives a flat (orthographic) flip.
  final double perspective;

  /// The axis position, relative to the child.
  final Alignment alignment;

  @override
  Widget build(
    BuildContext context,
    Widget child,
    AnimationController controller,
    EffectEntry entry,
  ) {
    final turns = buildAnimation(controller, entry);
    return AnimatedBuilder(
      animation: turns,
      child: child,
      builder: (context, child) {
        final angle = turns.value * math.pi;
        final matrix = Matrix4.identity()..setEntry(3, 2, 0.002 * perspective);
        matrix.multiply(
          direction == Axis.vertical
              ? Matrix4.rotationX(angle)
              : Matrix4.rotationY(angle),
        );
        return Transform(
          alignment: alignment,
          transform: matrix,
          child: child,
        );
      },
    );
  }
}

/// Adds flip effects to chains.
extension FlipEffectExtensions<T extends EffectChain<T>> on T {
  /// Flips between two values in turns (see [FlipEffect]).
  T flip({
    Duration? delay,
    Duration? duration,
    Curve? curve,
    double? begin,
    double? end,
    Axis direction = Axis.vertical,
    double perspective = 1,
    Alignment alignment = Alignment.center,
  }) =>
      addEffect(
        FlipEffect(
          delay: delay,
          duration: duration,
          curve: curve,
          begin: begin,
          end: end,
          direction: direction,
          perspective: perspective,
          alignment: alignment,
        ),
      );

  /// Flips horizontally, about the vertical (y) axis.
  T flipH({
    Duration? delay,
    Duration? duration,
    Curve? curve,
    double? begin,
    double? end,
    double perspective = 1,
    Alignment alignment = Alignment.center,
  }) =>
      flip(
        delay: delay,
        duration: duration,
        curve: curve,
        begin: begin,
        end: end,
        direction: Axis.horizontal,
        perspective: perspective,
        alignment: alignment,
      );

  /// Flips vertically, about the horizontal (x) axis.
  T flipV({
    Duration? delay,
    Duration? duration,
    Curve? curve,
    double? begin,
    double? end,
    double perspective = 1,
    Alignment alignment = Alignment.center,
  }) =>
      flip(
        delay: delay,
        duration: duration,
        curve: curve,
        begin: begin,
        end: end,
        perspective: perspective,
        alignment: alignment,
      );
}
