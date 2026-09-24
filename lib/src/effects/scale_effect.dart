import 'package:flutter/widgets.dart';

import '../effect.dart';

/// Scales on x and y (via [Transform]).
///
/// Defaults: `begin` `Offset(0, 0)` and `end` `Offset(1, 1)`. If only `end`
/// is given, `begin` is `Offset(1, 1)`. Scales smaller than 1e-6 are
/// clamped so the transform stays invertible (hit testing keeps working).
@immutable
class ScaleEffect extends Effect<Offset> {
  /// Creates a scale effect.
  const ScaleEffect({
    super.delay,
    super.duration,
    super.curve,
    Offset? begin,
    Offset? end,
    this.alignment = Alignment.center,
    this.transformHitTests = true,
  }) : super(
          begin: begin ?? (end == null ? Offset.zero : const Offset(1, 1)),
          end: end ?? const Offset(1, 1),
        );

  /// The origin of the scale, relative to the child.
  final AlignmentGeometry alignment;

  /// Whether hit tests follow the scaled area.
  final bool transformHitTests;

  static double _safe(double v) =>
      v.abs() < 1e-6 ? (v.isNegative ? -1e-6 : 1e-6) : v;

  @override
  Widget build(
    BuildContext context,
    Widget child,
    AnimationController controller,
    EffectEntry entry,
  ) {
    final scale = buildAnimation(controller, entry);
    return AnimatedBuilder(
      animation: scale,
      child: child,
      builder: (context, child) => Transform(
        alignment: alignment,
        transformHitTests: transformHitTests,
        transform: Matrix4.diagonal3Values(
          _safe(scale.value.dx),
          _safe(scale.value.dy),
          1,
        ),
        child: child,
      ),
    );
  }
}

/// Adds scale effects to chains.
extension ScaleEffectExtensions<T extends EffectChain<T>> on T {
  /// Scales between two x/y scale pairs (see [ScaleEffect]).
  T scale({
    Duration? delay,
    Duration? duration,
    Curve? curve,
    Offset? begin,
    Offset? end,
    AlignmentGeometry alignment = Alignment.center,
    bool transformHitTests = true,
  }) =>
      addEffect(
        ScaleEffect(
          delay: delay,
          duration: duration,
          curve: curve,
          begin: begin,
          end: end,
          alignment: alignment,
          transformHitTests: transformHitTests,
        ),
      );

  /// Scales horizontally only. Defaults: `begin` 0, `end` 1.
  T scaleX({
    Duration? delay,
    Duration? duration,
    Curve? curve,
    double? begin,
    double? end,
    AlignmentGeometry alignment = Alignment.center,
  }) =>
      addEffect(
        ScaleEffect(
          delay: delay,
          duration: duration,
          curve: curve,
          begin: Offset(begin ?? (end == null ? 0 : 1), 1),
          end: Offset(end ?? 1, 1),
          alignment: alignment,
        ),
      );

  /// Scales vertically only. Defaults: `begin` 0, `end` 1.
  T scaleY({
    Duration? delay,
    Duration? duration,
    Curve? curve,
    double? begin,
    double? end,
    AlignmentGeometry alignment = Alignment.center,
  }) =>
      addEffect(
        ScaleEffect(
          delay: delay,
          duration: duration,
          curve: curve,
          begin: Offset(1, begin ?? (end == null ? 0 : 1)),
          end: Offset(1, end ?? 1),
          alignment: alignment,
        ),
      );

  /// Scales both axes uniformly. Defaults: `begin` 0, `end` 1.
  T scaleXY({
    Duration? delay,
    Duration? duration,
    Curve? curve,
    double? begin,
    double? end,
    AlignmentGeometry alignment = Alignment.center,
  }) {
    final b = begin ?? (end == null ? 0.0 : 1.0);
    final e = end ?? 1.0;
    return addEffect(
      ScaleEffect(
        delay: delay,
        duration: duration,
        curve: curve,
        begin: Offset(b, b),
        end: Offset(e, e),
        alignment: alignment,
      ),
    );
  }
}
