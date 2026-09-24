import 'package:flutter/widgets.dart';

import '../effect.dart';
import '../internal.dart';

/// Switches visibility (via [Visibility]) when the effect ends: before that
/// the child's visibility is `!end`, afterwards it is [end].
///
/// Defaults: `end` true (hidden, then shown). With [maintain] (the default)
/// the hidden child keeps its size, state and animations.
@immutable
class VisibilityEffect extends Effect<bool> {
  /// Creates a visibility effect.
  const VisibilityEffect({
    super.delay,
    super.duration,
    bool end = true,
    this.maintain = true,
  }) : super(begin: !end, end: end);

  /// Whether the hidden child keeps its layout space and state.
  final bool maintain;

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
      builder: (context, passed) => Visibility(
        visible: passed ? end! : begin!,
        maintainSize: maintain,
        maintainAnimation: maintain,
        maintainState: maintain,
        maintainSemantics: maintain,
        maintainInteractivity: maintain,
        child: child,
      ),
    );
  }
}

/// Adds visibility effects to chains.
extension VisibilityEffectExtensions<T extends EffectChain<T>> on T {
  /// Switches visibility to [end] when this effect ends.
  T visibility({
    Duration? delay,
    Duration? duration,
    bool end = true,
    bool maintain = true,
  }) =>
      addEffect(
        VisibilityEffect(
          delay: delay,
          duration: duration,
          end: end,
          maintain: maintain,
        ),
      );

  /// Hidden until this effect ends, then shown.
  T show({Duration? delay, Duration? duration, bool maintain = true}) =>
      visibility(delay: delay, duration: duration, maintain: maintain);

  /// Shown until this effect ends, then hidden.
  T hide({Duration? delay, Duration? duration, bool maintain = true}) =>
      visibility(
        delay: delay,
        duration: duration,
        end: false,
        maintain: maintain,
      );
}
