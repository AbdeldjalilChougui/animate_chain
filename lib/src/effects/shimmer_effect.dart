import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import '../effect.dart';

/// Sweeps a gradient band across the child (the "loading shimmer").
///
/// Implementation: one [ShaderMaskLayer] from a small render object that
/// listens to the animation and only repaints. Nothing is rebuilt per frame
/// and the child sits behind a [RepaintBoundary], so its picture is recorded
/// once and reused while the band moves; this keeps large children cheap.
/// Unlike some shimmer implementations, no padding is added, so the child's
/// size is unchanged.
///
/// Defaults: [color] 50% white, [size] 1 (band as wide as the child),
/// [angle] pi/12 radians, [blendMode] [BlendMode.srcATop] (the band only
/// shows over the child's opaque pixels).
@immutable
class ShimmerEffect extends Effect<double> {
  /// Creates a shimmer effect.
  const ShimmerEffect({
    super.delay,
    super.duration,
    super.curve,
    this.color = const Color(0x80FFFFFF),
    this.colors,
    this.stops,
    this.size = 1,
    this.angle = math.pi / 12,
    this.blendMode = BlendMode.srcATop,
  })  : assert(size > 0),
        super(begin: 0, end: 1);

  /// Colour of the band's centre when [colors] is null. The band fades from
  /// transparent to [color] and back.
  final Color color;

  /// Full list of gradient colours; overrides [color].
  final List<Color>? colors;

  /// Gradient stops for [colors].
  final List<double>? stops;

  /// Band width relative to the child's extent along the sweep direction.
  final double size;

  /// Sweep direction in radians (0 sweeps left to right).
  final double angle;

  /// How the band is composited with the child.
  final BlendMode blendMode;

  @override
  Widget build(
    BuildContext context,
    Widget child,
    AnimationController controller,
    EffectEntry entry,
  ) {
    return RepaintBoundary(
      child: _ShimmerMask(
        progress: entry.animate(controller),
        effect: this,
        child: RepaintBoundary(child: child),
      ),
    );
  }

  /// Builds the band's shader for a child of [bounds] size at [progress].
  ui.Shader _shader(Size bounds, double progress) {
    final w = math.max(bounds.width, 0.01);
    final h = math.max(bounds.height, 0.01);
    final dir = Offset(math.cos(angle), math.sin(angle));
    final span = (w * dir.dx).abs() + (h * dir.dy).abs();
    final band = span * size;
    final travel = (span + band) / 2;
    final pos = -travel + 2 * travel * progress;
    final centre = Offset(w / 2, h / 2) + dir * pos;
    final clear = Color.lerp(null, color, 0)!;
    final list = colors ?? [clear, color, clear];
    return ui.Gradient.linear(
      centre - dir * (band / 2),
      centre + dir * (band / 2),
      list,
      stops ?? _evenStops(list.length),
    );
  }
}

List<double>? _evenStops(int count) =>
    count == 2 ? null : [for (var i = 0; i < count; i++) i / (count - 1)];

class _ShimmerMask extends SingleChildRenderObjectWidget {
  const _ShimmerMask({
    required this.progress,
    required this.effect,
    required super.child,
  });

  final Animation<double> progress;
  final ShimmerEffect effect;

  @override
  _RenderShimmer createRenderObject(BuildContext context) =>
      _RenderShimmer(progress, effect);

  @override
  void updateRenderObject(BuildContext context, _RenderShimmer renderObject) {
    renderObject
      ..progress = progress
      ..effect = effect;
  }
}

class _RenderShimmer extends RenderProxyBox {
  _RenderShimmer(this._progress, this._effect);

  Animation<double> _progress;
  set progress(Animation<double> value) {
    if (identical(value, _progress)) return;
    if (attached) _progress.removeListener(_onTick);
    _progress = value;
    if (attached) _progress.addListener(_onTick);
    markNeedsPaint();
  }

  ShimmerEffect _effect;
  set effect(ShimmerEffect value) {
    if (identical(value, _effect)) return;
    _effect = value;
    markNeedsPaint();
  }

  double? _painted;

  void _onTick() {
    if (_progress.value != _painted) markNeedsPaint();
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _progress.addListener(_onTick);
  }

  @override
  void detach() {
    _progress.removeListener(_onTick);
    super.detach();
  }

  @override
  bool get alwaysNeedsCompositing => child != null;

  @override
  ShaderMaskLayer? get layer => super.layer as ShaderMaskLayer?;

  @override
  void paint(PaintingContext context, Offset offset) {
    if (child == null) {
      layer = null;
      return;
    }
    final value = _progress.value;
    _painted = value;
    final mask = layer ?? ShaderMaskLayer();
    mask
      ..shader = _effect._shader(size, value)
      ..maskRect = offset & size
      ..blendMode = _effect.blendMode;
    layer = mask;
    context.pushLayer(mask, super.paint, offset);
  }
}

/// Adds `shimmer()` to chains.
extension ShimmerEffectExtensions<T extends EffectChain<T>> on T {
  /// Adds a [ShimmerEffect].
  T shimmer({
    Duration? delay,
    Duration? duration,
    Curve? curve,
    Color color = const Color(0x80FFFFFF),
    List<Color>? colors,
    List<double>? stops,
    double size = 1,
    double angle = math.pi / 12,
    BlendMode blendMode = BlendMode.srcATop,
  }) =>
      addEffect(
        ShimmerEffect(
          delay: delay,
          duration: duration,
          curve: curve,
          color: color,
          colors: colors,
          stops: stops,
          size: size,
          angle: angle,
          blendMode: blendMode,
        ),
      );
}
