/// Short-hand [Duration] constructors on numbers, e.g. `300.ms`, `1.5.seconds`.
extension AnimateDurationExtensions on num {
  /// This number as a [Duration] in milliseconds.
  Duration get ms => Duration(microseconds: (this * 1000).round());

  /// This number as a [Duration] in milliseconds.
  Duration get milliseconds => ms;

  /// This number as a [Duration] in seconds.
  Duration get seconds => Duration(microseconds: (this * 1000000).round());

  /// This number as a [Duration] in minutes.
  Duration get minutes => Duration(microseconds: (this * 60000000).round());
}
