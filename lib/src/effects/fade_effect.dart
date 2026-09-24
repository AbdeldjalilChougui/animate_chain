import 'package:flutter/widgets.dart';

import '../effect.dart';

/// Animates opacity (via [FadeTransition]). Values are clamped to 0-1.
///
/// Defaults: `begin` 0 and `end` 1. If only `end` is given, `begin` is 1.
@immutable
class FadeEffect extends Effect<double> {
  /// Creates a fade effect.
  const FadeEffect({
    super.delay,
    super.duration,
    super.curve,
    double? begin,
    double? end,
  }) : super(
          begin: begin ?? (end == null ? 0.0 : 1.0),
          end: end ?? 1.0,
        );

  @override
  Widget build(
    BuildContext context,
    Widget child,
    AnimationController controller,
    EffectEntry entry,
  ) {
    return FadeTransition(
      opacity: entry.animate(controller).drive(_OpacityTween(begin!, end!)),
      child: child,
    );
  }
}

class _OpacityTween extends Animatable<double> {
  const _OpacityTween(this.begin, this.end);
  final double begin;
  final double end;

  @override
  double transform(double t) => (begin + (end - begin) * t).clamp(0.0, 1.0);
}

/// Adds fade effects to chains.
extension FadeEffectExtensions<T extends EffectChain<T>> on T {
  /// Fades between [begin] and [end] (see [FadeEffect] for defaults).
  T fade({
    Duration? delay,
    Duration? duration,
    Curve? curve,
    double? begin,
    double? end,
  }) =>
      addEffect(
        FadeEffect(
          delay: delay,
          duration: duration,
          curve: curve,
          begin: begin,
          end: end,
        ),
      );

  /// Fades from [begin] (default 0) to fully opaque.
  T fadeIn({
    Duration? delay,
    Duration? duration,
    Curve? curve,
    double? begin,
  }) =>
      addEffect(
        FadeEffect(
          delay: delay,
          duration: duration,
          curve: curve,
          begin: begin ?? 0,
          end: 1,
        ),
      );

  /// Fades from [begin] (default 1) to fully transparent.
  T fadeOut({
    Duration? delay,
    Duration? duration,
    Curve? curve,
    double? begin,
  }) =>
      addEffect(
        FadeEffect(
          delay: delay,
          duration: duration,
          curve: curve,
          begin: begin ?? 1,
          end: 0,
        ),
      );
}
