import 'package:flutter/widgets.dart';

import '../effect.dart';
import '../internal.dart';

/// When this effect ends, replaces everything built so far (the child and
/// all preceding effects) with the result of [builder].
///
/// [builder] receives the original, un-animated child of the [Animate], so
/// it can start a fresh chain:
///
/// ```dart
/// text.animate().fadeOut(duration: 300.ms)
///     .swap(builder: (_, child) => child.animate().fadeIn())
/// ```
@immutable
class SwapEffect extends Effect<void> {
  /// Creates a swap effect.
  const SwapEffect({super.delay, super.duration, required this.builder});

  /// Builds the replacement from the original child.
  final Widget Function(BuildContext context, Widget originalChild) builder;

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
      builder: (context, passed) =>
          passed ? builder(context, entry.owner.child) : child,
    );
  }
}

/// Adds `swap()` to chains.
extension SwapEffectExtensions<T extends EffectChain<T>> on T {
  /// Adds a [SwapEffect].
  T swap({
    required Widget Function(BuildContext context, Widget originalChild)
        builder,
    Duration? delay,
    Duration? duration,
  }) =>
      addEffect(
        SwapEffect(builder: builder, delay: delay, duration: duration),
      );
}
