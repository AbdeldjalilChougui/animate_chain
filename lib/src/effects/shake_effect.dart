import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../effect.dart';

/// Shakes back and forth with a sine wave, by translation, rotation or both
/// (via [Transform]).
///
/// [hz] is the approximate number of shakes per second; it is rounded so a
/// whole number of cycles fits the duration, which makes the child rest
/// exactly in place at the start and the end. Defaults: `hz` 8,
/// `rotation` pi/36 radians (5 degrees), `offset` `Offset.zero`.
@immutable
class ShakeEffect extends Effect<double> {
  /// Creates a shake effect.
  const ShakeEffect({
    super.delay,
    super.duration,
    super.curve,
    this.hz = 8,
    this.offset = Offset.zero,
    this.rotation = math.pi / 36,
  }) : super(begin: 0, end: 1);

  /// Approximate shakes per second.
  final double hz;

  /// Peak translation in pixels.
  final Offset offset;

  /// Peak rotation in radians.
  final double rotation;

  @override
  Widget build(
    BuildContext context,
    Widget child,
    AnimationController controller,
    EffectEntry entry,
  ) {
    final seconds = entry.duration.inMicroseconds / 1e6;
    final cycles = math.max(1, (hz * seconds).round());
    final progress = entry.animate(controller);
    return AnimatedBuilder(
      animation: progress,
      child: child,
      builder: (context, child) {
        final s = math.sin(progress.value * cycles * 2 * math.pi);
        final matrix =
            Matrix4.translationValues(offset.dx * s, offset.dy * s, 0)
              ..multiply(Matrix4.rotationZ(rotation * s));
        return Transform(
          alignment: Alignment.center,
          transform: matrix,
          child: child,
        );
      },
    );
  }
}

/// Adds shake effects to chains.
extension ShakeEffectExtensions<T extends EffectChain<T>> on T {
  /// Shakes with rotation and/or translation (see [ShakeEffect]).
  T shake({
    Duration? delay,
    Duration? duration,
    Curve? curve,
    double hz = 8,
    Offset offset = Offset.zero,
    double rotation = math.pi / 36,
  }) =>
      addEffect(
        ShakeEffect(
          delay: delay,
          duration: duration,
          curve: curve,
          hz: hz,
          offset: offset,
          rotation: rotation,
        ),
      );

  /// Shakes horizontally by [amount] pixels (default 5), without rotation.
  T shakeX({
    Duration? delay,
    Duration? duration,
    Curve? curve,
    double hz = 8,
    double amount = 5,
  }) =>
      shake(
        delay: delay,
        duration: duration,
        curve: curve,
        hz: hz,
        offset: Offset(amount, 0),
        rotation: 0,
      );

  /// Shakes vertically by [amount] pixels (default 5), without rotation.
  T shakeY({
    Duration? delay,
    Duration? duration,
    Curve? curve,
    double hz = 8,
    double amount = 5,
  }) =>
      shake(
        delay: delay,
        duration: duration,
        curve: curve,
        hz: hz,
        offset: Offset(0, amount),
        rotation: 0,
      );
}
