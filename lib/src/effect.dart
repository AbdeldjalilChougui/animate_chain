import 'package:flutter/widgets.dart';

import 'animate.dart';
import 'internal.dart';

/// Anything that effects can be chained onto: [Animate] and [AnimateList].
///
/// Every chain method (`fadeIn`, `slideY`, `then`, ...) is an extension on
/// this mixin and ends in a call to [addEffect].
mixin EffectChain<T> {
  /// Returns a new chain with [effect] appended.
  T addEffect(Effect<Object?> effect);
}

/// Base class for all effects. On its own it has no visual effect.
///
/// Effects are immutable descriptions. Any timing value left `null` is
/// inherited from the previous effect in the chain (see [Animate]); the
/// resolved timing for one [Animate] is stored in an [EffectEntry].
///
/// To write your own effect, extend this class and override [build]. Prefer
/// [EffectEntry.animate] over creating `CurvedAnimation`s: it registers no
/// listeners of its own, so there is nothing to dispose.
@immutable
class Effect<T> {
  /// Creates an effect. All values are optional.
  const Effect({this.delay, this.duration, this.curve, this.begin, this.end});

  /// Delay before this effect starts, relative to the chain's current
  /// baseline. `null` inherits the previous effect's delay.
  final Duration? delay;

  /// How long this effect runs. `null` inherits the previous effect's
  /// duration, or [Animate.defaultDuration] for the first effect.
  final Duration? duration;

  /// Easing curve. `null` inherits the previous effect's curve, or
  /// [Animate.defaultCurve] for the first effect.
  final Curve? curve;

  /// Value at the start of the effect.
  final T? begin;

  /// Value at the end of the effect.
  final T? end;

  /// Wraps [child] with whatever widgets implement this effect.
  ///
  /// [controller] is the single controller owned (or used) by the enclosing
  /// [Animate]; [entry] holds this effect's resolved timing.
  Widget build(
    BuildContext context,
    Widget child,
    AnimationController controller,
    EffectEntry entry,
  ) =>
      child;

  /// An animation of this effect's value, from [begin] to [end], following
  /// [entry]'s interval and curve. It is a listener-free view of
  /// [controller], so it needs no disposal.
  Animation<T> buildAnimation(
    AnimationController controller,
    EffectEntry entry,
  ) =>
      entry.animate(controller).drive(Tween<T>(begin: begin, end: end));
}

/// The resolved timing of one [Effect] inside one [Animate].
///
/// Effects are shareable, so their inherited values live here instead.
@immutable
class EffectEntry {
  /// Creates an entry. Normally only [Animate] does this.
  const EffectEntry({
    required this.effect,
    required this.delay,
    required this.duration,
    required this.curve,
    required this.total,
    required this.owner,
  });

  /// The effect this entry belongs to.
  final Effect<Object?> effect;

  /// Resolved start time, from the start of the animation.
  final Duration delay;

  /// Resolved duration.
  final Duration duration;

  /// Resolved curve.
  final Curve curve;

  /// Total duration of the owning [Animate].
  final Duration total;

  /// The [Animate] this entry belongs to.
  final Animate owner;

  /// Resolved end time ([delay] + [duration]).
  Duration get end => delay + duration;

  /// The controller value (0-1) at which this entry ends.
  ///
  /// When the whole animation has zero length this is `0`.
  double get endRatio {
    final total = this.total.inMicroseconds;
    return total == 0 ? 0 : end.inMicroseconds / total;
  }

  /// Linear 0-1 progress of this entry at controller value [t].
  double linearProgress(double t) {
    final total = this.total.inMicroseconds;
    if (total == 0) return 1;
    final now = t * total;
    final start = delay.inMicroseconds;
    final length = duration.inMicroseconds;
    if (length == 0) return now >= start ? 1 : 0;
    return ((now - start) / length).clamp(0.0, 1.0);
  }

  /// Curved progress of this entry at controller value [t].
  double progress(double t) => curve.transform(linearProgress(t));

  /// A listener-free animation of this entry's curved progress, driven by
  /// [parent] (normally the [Animate]'s controller).
  Animation<double> animate(Animation<double> parent) =>
      EntryAnimation(parent, this);
}

/// Starts a new timing baseline at the end of the previous effect.
///
/// Effects after it without a `delay` start where the previous effect ended;
/// an explicit `delay` is added to that point. `duration` and `curve`, if
/// given, are inherited by the effects that follow.
@immutable
class ThenEffect extends Effect<void> {
  /// Creates a then marker.
  const ThenEffect({super.delay, super.duration, super.curve});
}

/// Adds `then()` to effect chains.
extension ThenEffectExtensions<T extends EffectChain<T>> on T {
  /// Makes the following effects start after the previous effect ends
  /// (plus [delay]). [duration] and [curve] become the inherited defaults.
  T then({Duration? delay, Duration? duration, Curve? curve}) =>
      addEffect(ThenEffect(delay: delay, duration: duration, curve: curve));
}
