import 'package:flutter/widgets.dart';

import '../effect.dart';

/// Moves by a pixel offset (via [Transform.translate]).
///
/// Defaults: `begin` `Offset(0, -16)` and `end` `Offset.zero`. If only `end`
/// is given, `begin` is `Offset.zero`.
@immutable
class MoveEffect extends Effect<Offset> {
  /// Creates a move effect.
  const MoveEffect({
    super.delay,
    super.duration,
    super.curve,
    Offset? begin,
    Offset? end,
    this.transformHitTests = true,
  }) : super(
          begin: begin ?? (end == null ? const Offset(0, -16) : Offset.zero),
          end: end ?? Offset.zero,
        );

  /// Whether hit tests follow the moved position.
  final bool transformHitTests;

  @override
  Widget build(
    BuildContext context,
    Widget child,
    AnimationController controller,
    EffectEntry entry,
  ) {
    final offset = buildAnimation(controller, entry);
    return AnimatedBuilder(
      animation: offset,
      child: child,
      builder: (context, child) => Transform.translate(
        offset: offset.value,
        transformHitTests: transformHitTests,
        child: child,
      ),
    );
  }
}

/// Adds move effects to chains.
extension MoveEffectExtensions<T extends EffectChain<T>> on T {
  /// Moves between two pixel offsets (see [MoveEffect]).
  T move({
    Duration? delay,
    Duration? duration,
    Curve? curve,
    Offset? begin,
    Offset? end,
    bool transformHitTests = true,
  }) =>
      addEffect(
        MoveEffect(
          delay: delay,
          duration: duration,
          curve: curve,
          begin: begin,
          end: end,
          transformHitTests: transformHitTests,
        ),
      );

  /// Moves horizontally. Defaults: `begin` -16, `end` 0.
  T moveX({
    Duration? delay,
    Duration? duration,
    Curve? curve,
    double? begin,
    double? end,
    bool transformHitTests = true,
  }) =>
      addEffect(
        MoveEffect(
          delay: delay,
          duration: duration,
          curve: curve,
          begin: Offset(begin ?? (end == null ? -16 : 0), 0),
          end: Offset(end ?? 0, 0),
          transformHitTests: transformHitTests,
        ),
      );

  /// Moves vertically. Defaults: `begin` -16, `end` 0.
  T moveY({
    Duration? delay,
    Duration? duration,
    Curve? curve,
    double? begin,
    double? end,
    bool transformHitTests = true,
  }) =>
      addEffect(
        MoveEffect(
          delay: delay,
          duration: duration,
          curve: curve,
          begin: Offset(0, begin ?? (end == null ? -16 : 0)),
          end: Offset(0, end ?? 0),
          transformHitTests: transformHitTests,
        ),
      );
}
