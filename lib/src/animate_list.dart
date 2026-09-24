import 'dart:collection';

import 'package:flutter/widgets.dart';

import 'animate.dart';
import 'effect.dart';

/// A list of widgets that each get the same effects, staggered by
/// [interval]. Use it directly as `children` of a `Column`, `Row`, etc.
///
/// ```dart
/// Column(children: [a, b, c].animate(interval: 80.ms).fadeIn().slideX())
/// ```
///
/// Child `i` is wrapped in an [Animate] whose delay is
/// `delay + interval * i`. [Spacer]s are passed through unwrapped because
/// they must be direct children of a `Flex`.
///
/// The list is unmodifiable; each chain call returns a new list.
class AnimateList extends ListBase<Widget> with EffectChain<AnimateList> {
  /// Creates a staggered list from [children].
  AnimateList({
    required List<Widget> children,
    List<Effect<Object?>>? effects,
    this.onInit,
    this.onPlay,
    this.onComplete,
    this.autoPlay = true,
    this.delay = Duration.zero,
    this.interval = Duration.zero,
  })  : children = List.unmodifiable(children),
        effects = List.unmodifiable(effects ?? const <Effect<Object?>>[]);

  /// The original, unwrapped children.
  final List<Widget> children;

  /// The effects applied to every child.
  final List<Effect<Object?>> effects;

  /// See [Animate.onInit].
  final AnimateCallback? onInit;

  /// See [Animate.onPlay].
  final AnimateCallback? onPlay;

  /// See [Animate.onComplete]. Called for each child.
  final AnimateCallback? onComplete;

  /// See [Animate.autoPlay].
  final bool autoPlay;

  /// Delay before the first child starts.
  final Duration delay;

  /// Extra delay added for each following child.
  final Duration interval;

  late final List<Widget> _wrapped = [
    for (var i = 0; i < children.length; i++) _wrap(children[i], i),
  ];

  Widget _wrap(Widget child, int index) {
    if (child is Spacer) return child;
    return Animate(
      effects: effects,
      onInit: onInit,
      onPlay: onPlay,
      onComplete: onComplete,
      autoPlay: autoPlay,
      delay: delay + interval * index,
      child: child,
    );
  }

  @override
  int get length => children.length;

  @override
  set length(int newLength) =>
      throw UnsupportedError('Cannot change the length of an AnimateList');

  @override
  Widget operator [](int index) => _wrapped[index];

  @override
  void operator []=(int index, Widget value) =>
      throw UnsupportedError('Cannot modify an AnimateList');

  @override
  AnimateList addEffect(Effect<Object?> effect) => AnimateList(
        effects: [...effects, effect],
        onInit: onInit,
        onPlay: onPlay,
        onComplete: onComplete,
        autoPlay: autoPlay,
        delay: delay,
        interval: interval,
        children: children,
      );
}

/// Adds `animate()` to lists of widgets.
extension AnimateListExtensions on List<Widget> {
  /// Wraps every widget in an [Animate], staggered by [interval].
  AnimateList animate({
    List<Effect<Object?>>? effects,
    AnimateCallback? onInit,
    AnimateCallback? onPlay,
    AnimateCallback? onComplete,
    bool autoPlay = true,
    Duration delay = Duration.zero,
    Duration interval = Duration.zero,
  }) =>
      AnimateList(
        effects: effects,
        onInit: onInit,
        onPlay: onPlay,
        onComplete: onComplete,
        autoPlay: autoPlay,
        delay: delay,
        interval: interval,
        children: this,
      );
}
