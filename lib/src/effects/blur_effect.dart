import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/widgets.dart';

import '../effect.dart';

/// Gaussian blur (via [ImageFiltered]); the value is the x/y sigma.
///
/// Defaults: `begin` `Offset.zero` and `end` `Offset(4, 4)`. If only `begin`
/// is given, `end` is `Offset.zero`. Sigmas are clamped at 0, so curves that
/// overshoot cannot produce an invalid filter, and the filter is disabled
/// (no offscreen layer) below 0.01.
@immutable
class BlurEffect extends Effect<Offset> {
  /// Creates a blur effect.
  const BlurEffect({
    super.delay,
    super.duration,
    super.curve,
    Offset? begin,
    Offset? end,
  }) : super(
          begin: begin ?? Offset.zero,
          end: end ?? (begin == null ? const Offset(4, 4) : Offset.zero),
        );

  @override
  Widget build(
    BuildContext context,
    Widget child,
    AnimationController controller,
    EffectEntry entry,
  ) {
    final sigma = buildAnimation(controller, entry);
    return AnimatedBuilder(
      animation: sigma,
      child: child,
      builder: (context, child) {
        final x = math.max(0.0, sigma.value.dx);
        final y = math.max(0.0, sigma.value.dy);
        return ImageFiltered(
          enabled: x >= 0.01 || y >= 0.01,
          imageFilter: ImageFilter.blur(sigmaX: x, sigmaY: y),
          child: child,
        );
      },
    );
  }
}

/// Adds blur effects to chains.
extension BlurEffectExtensions<T extends EffectChain<T>> on T {
  /// Blurs between two x/y sigmas (see [BlurEffect]).
  T blur({
    Duration? delay,
    Duration? duration,
    Curve? curve,
    Offset? begin,
    Offset? end,
  }) =>
      addEffect(
        BlurEffect(
          delay: delay,
          duration: duration,
          curve: curve,
          begin: begin,
          end: end,
        ),
      );

  /// Blurs horizontally. Defaults: `begin` 0, `end` 4.
  T blurX({
    Duration? delay,
    Duration? duration,
    Curve? curve,
    double? begin,
    double? end,
  }) =>
      blur(
        delay: delay,
        duration: duration,
        curve: curve,
        begin: Offset(begin ?? 0, 0),
        end: Offset(end ?? (begin == null ? 4 : 0), 0),
      );

  /// Blurs vertically. Defaults: `begin` 0, `end` 4.
  T blurY({
    Duration? delay,
    Duration? duration,
    Curve? curve,
    double? begin,
    double? end,
  }) =>
      blur(
        delay: delay,
        duration: duration,
        curve: curve,
        begin: Offset(0, begin ?? 0),
        end: Offset(0, end ?? (begin == null ? 4 : 0)),
      );

  /// Blurs both axes uniformly. Defaults: `begin` 0, `end` 4.
  T blurXY({
    Duration? delay,
    Duration? duration,
    Curve? curve,
    double? begin,
    double? end,
  }) {
    final b = begin ?? 0.0;
    final e = end ?? (begin == null ? 4.0 : 0.0);
    return blur(
      delay: delay,
      duration: duration,
      curve: curve,
      begin: Offset(b, b),
      end: Offset(e, e),
    );
  }
}
