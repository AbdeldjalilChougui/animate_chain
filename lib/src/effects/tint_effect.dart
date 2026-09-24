import 'dart:ui' show lerpDouble;

import 'package:flutter/widgets.dart';

import '../effect.dart';

/// Tints the child toward [color] (via a [ColorFiltered] in
/// [BlendMode.srcATop], so transparent areas stay transparent).
///
/// The value is the tint strength, 0-1, scaled by [color]'s own alpha.
/// Defaults: `begin` 0 and `end` 1; if only `begin` is given, `end` is 0.
@immutable
class TintEffect extends Effect<double> {
  /// Creates a tint effect.
  const TintEffect({
    super.delay,
    super.duration,
    super.curve,
    double? begin,
    double? end,
    this.color = const Color(0xFF000000),
  }) : super(
          begin: begin ?? 0.0,
          end: end ?? (begin == null ? 1.0 : 0.0),
        );

  /// The tint colour. Defaults to opaque black.
  final Color color;

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
        final amount = lerpDouble(begin, end, progress.value)!.clamp(0.0, 1.0);
        return ColorFiltered(
          colorFilter: ColorFilter.mode(
            Color.lerp(null, color, amount)!,
            BlendMode.srcATop,
          ),
          child: child,
        );
      },
    );
  }
}

/// Adds tint effects to chains.
extension TintEffectExtensions<T extends EffectChain<T>> on T {
  /// Tints toward [color] (see [TintEffect]).
  T tint({
    Duration? delay,
    Duration? duration,
    Curve? curve,
    double? begin,
    double? end,
    Color color = const Color(0xFF000000),
  }) =>
      addEffect(
        TintEffect(
          delay: delay,
          duration: duration,
          curve: curve,
          begin: begin,
          end: end,
          color: color,
        ),
      );

  /// Removes a tint: from [begin] (default 1) to 0.
  T untint({
    Duration? delay,
    Duration? duration,
    Curve? curve,
    double? begin,
    Color color = const Color(0xFF000000),
  }) =>
      tint(
        delay: delay,
        duration: duration,
        curve: curve,
        begin: begin ?? 1,
        end: 0,
        color: color,
      );
}
