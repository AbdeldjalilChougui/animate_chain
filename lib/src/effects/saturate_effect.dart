import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/widgets.dart';

import '../effect.dart';

/// Animates colour saturation (via a [ColorFiltered] colour matrix using
/// Rec. 709 luma weights). 0 is greyscale, 1 is unchanged, above 1 is
/// over-saturated.
///
/// Defaults: `begin` 0 and `end` 1. If only `end` is given, `begin` is 1.
@immutable
class SaturateEffect extends Effect<double> {
  /// Creates a saturation effect.
  const SaturateEffect({
    super.delay,
    super.duration,
    super.curve,
    double? begin,
    double? end,
  }) : super(begin: begin ?? (end == null ? 0.0 : 1.0), end: end ?? 1.0);

  static const double _r = 0.2126, _g = 0.7152, _b = 0.0722;

  /// The colour matrix for saturation [s].
  static List<double> matrix(double s) {
    final i = 1 - s;
    return [
      _r * i + s, _g * i, _b * i, 0, 0, //
      _r * i, _g * i + s, _b * i, 0, 0, //
      _r * i, _g * i, _b * i + s, 0, 0, //
      0, 0, 0, 1, 0,
    ];
  }

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
      builder: (context, child) {
        final s = math.max(0.0, lerpDouble(begin, end, progress.value)!);
        return ColorFiltered(
          colorFilter: ColorFilter.matrix(matrix(s)),
          child: child,
        );
      },
    );
  }
}

/// Adds saturation effects to chains.
extension SaturateEffectExtensions<T extends EffectChain<T>> on T {
  /// Animates saturation (see [SaturateEffect]).
  T saturate({
    Duration? delay,
    Duration? duration,
    Curve? curve,
    double? begin,
    double? end,
  }) =>
      addEffect(
        SaturateEffect(
          delay: delay,
          duration: duration,
          curve: curve,
          begin: begin,
          end: end,
        ),
      );

  /// Desaturates from [begin] (default 1) to [end] (default 0).
  T desaturate({
    Duration? delay,
    Duration? duration,
    Curve? curve,
    double? begin,
    double? end,
  }) =>
      saturate(
        delay: delay,
        duration: duration,
        curve: curve,
        begin: begin ?? 1,
        end: end ?? 0,
      );
}
