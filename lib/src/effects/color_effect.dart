import 'package:flutter/widgets.dart';

import '../effect.dart';

/// Animates a colour applied through [ColorFilter.mode] (via
/// [ColorFiltered]), blended with [blendMode].
///
/// A `null` [begin] is the transparent version of [end], so the filter fades
/// in. When both are `null`, [end] defaults to a 50% blue.
@immutable
class ColorEffect extends Effect<Color> {
  /// Creates a colour effect.
  const ColorEffect({
    super.delay,
    super.duration,
    super.curve,
    super.begin,
    Color? end,
    this.blendMode = BlendMode.color,
  }) : super(end: end ?? (begin == null ? const Color(0x802196F3) : null));

  /// How the colour is combined with the child. Defaults to
  /// [BlendMode.color].
  final BlendMode blendMode;

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
      builder: (context, child) => ColorFiltered(
        colorFilter: ColorFilter.mode(
          Color.lerp(begin, end, progress.value) ?? const Color(0x00000000),
          blendMode,
        ),
        child: child,
      ),
    );
  }
}

/// Adds `color()` to chains.
extension ColorEffectExtensions<T extends EffectChain<T>> on T {
  /// Animates a colour filter (see [ColorEffect]).
  T color({
    Duration? delay,
    Duration? duration,
    Curve? curve,
    Color? begin,
    Color? end,
    BlendMode blendMode = BlendMode.color,
  }) =>
      addEffect(
        ColorEffect(
          delay: delay,
          duration: duration,
          curve: curve,
          begin: begin,
          end: end,
          blendMode: blendMode,
        ),
      );
}
