import 'package:flutter/widgets.dart';

import '../effect.dart';
import '../internal.dart';

/// Builds a widget from a boolean that flips when an effect ends.
typedef ToggleEffectBuilder = Widget Function(
  BuildContext context,
  bool value,
  Widget child,
);

/// Calls [builder] with `true` before this effect ends and `false` after.
/// It rebuilds only when the value flips, which makes it a good trigger for
/// implicit `Animated*` widgets.
@immutable
class ToggleEffect extends Effect<void> {
  /// Creates a toggle effect.
  const ToggleEffect({super.delay, super.duration, required this.builder});

  /// Builds the output for the current value.
  final ToggleEffectBuilder builder;

  @override
  Widget build(
    BuildContext context,
    Widget child,
    AnimationController controller,
    EffectEntry entry,
  ) {
    return ThresholdBuilder(
      animation: controller,
      threshold: entry.endRatio,
      builder: (context, passed) => builder(context, !passed, child),
    );
  }
}

/// Adds `toggle()` to chains.
extension ToggleEffectExtensions<T extends EffectChain<T>> on T {
  /// Adds a [ToggleEffect].
  T toggle({
    required ToggleEffectBuilder builder,
    Duration? delay,
    Duration? duration,
  }) =>
      addEffect(
        ToggleEffect(builder: builder, delay: delay, duration: duration),
      );
}
