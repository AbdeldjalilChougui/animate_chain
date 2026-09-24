/// Chained, declarative widget animations.
///
/// ```dart
/// Text('Hello').animate().fadeIn().slideY().then(delay: 200.ms).shake();
/// ```
library;

export 'src/adapters.dart';
export 'src/animate.dart';
export 'src/animate_list.dart';
export 'src/duration_extensions.dart';
export 'src/effect.dart';
export 'src/effects/blur_effect.dart';
export 'src/effects/callback_effect.dart';
export 'src/effects/color_effect.dart';
export 'src/effects/custom_effect.dart';
export 'src/effects/fade_effect.dart';
export 'src/effects/flip_effect.dart';
export 'src/effects/listen_effect.dart';
export 'src/effects/move_effect.dart';
export 'src/effects/rotate_effect.dart';
export 'src/effects/saturate_effect.dart';
export 'src/effects/scale_effect.dart';
export 'src/effects/shake_effect.dart';
export 'src/effects/shimmer_effect.dart';
export 'src/effects/slide_effect.dart';
export 'src/effects/swap_effect.dart';
export 'src/effects/tint_effect.dart';
export 'src/effects/toggle_effect.dart';
export 'src/effects/visibility_effect.dart';
