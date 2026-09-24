# animate_chain

Chained, declarative widget animations for Flutter: `widget.animate().fadeIn().slideY()`.
It covers the most-used core of the `flutter_animate` API in a clean-room rewrite, and fixes that
package's lifecycle bugs: timers left running after dispose, duplicate `onComplete` calls, stale
target changes and shimmer repaint cost.

[![pub package](https://img.shields.io/pub/v/animate_chain.svg)](https://pub.dev/packages/animate_chain)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

## Features

- **Chained or declarative**: `child.animate().fadeIn().scale()`, or
  `Animate(effects: [FadeEffect(), ScaleEffect()], child: child)`.
- **Sequencing with `then()`**: works the same way as in flutter_animate. Each effect after
  `then()` starts when the previous effect ends.
- **Inherited timing**: an effect that omits `delay`, `duration` or `curve` inherits it from the
  previous effect. The first effect falls back to `Animate.defaultDuration` (300 ms) and
  `Animate.defaultCurve` (linear).
- **18 effects**: fade, slide, move, scale, rotate, flip, blur, tint, color, shimmer, shake,
  saturate, custom, visibility, callback, listen, swap and toggle, plus their shortcuts
  (`fadeIn`, `slideX`, `scaleXY`, `shakeY`, `blurXY`, `flipH`, `show`, `hide`, and others).
- **Staggered lists**: `[a, b, c].animate(interval: 80.ms).fadeIn()`.
- **State-driven**: `animate(target: selected ? 1 : 0)` animates smoothly from the current
  position whenever `target` changes.
- **External drivers**: pass your own `controller`, or use `ScrollAdapter`,
  `ValueNotifierAdapter` or `ChangeNotifierAdapter`.
- **Accessibility**: when `MediaQuery.disableAnimations` is on, the widget jumps to its end
  state (configurable).
- **Leak-free**: one `AnimationController` per `Animate`, and no `CurvedAnimation`s to dispose.
  Pending delays are cancelled on dispose, and every listener is removed.

## Install

```yaml
dependencies:
  animate_chain: ^0.1.0
```

```dart
import 'package:animate_chain/animate_chain.dart';
```

## Usage

```dart
// Chained. Effects run in parallel unless delayed or sequenced with then().
Text('Hello')
    .animate()
    .fadeIn(duration: 400.ms)
    .slideY(begin: 0.3, curve: Curves.easeOut) // inherits 400ms
    .then(delay: 200.ms)                       // starts at 400 + 200 ms
    .shakeX();

// Declarative, reusable effect lists.
const pop = <Effect<Object?>>[
  FadeEffect(duration: Duration(milliseconds: 200)),
  ScaleEffect(begin: Offset(0.8, 0.8), curve: Curves.easeOutBack),
];
Animate(effects: pop, child: const Icon(Icons.star));

// Staggered list.
Column(
  children: [for (final item in items) ListTile(title: Text(item))]
      .animate(interval: 60.ms)
      .fadeIn()
      .moveX(begin: -24),
);

// State-driven: animates to the new target when `selected` changes.
card.animate(target: selected ? 1 : 0).scaleXY(begin: 1, end: 1.05).tint(end: 0.2);

// Looping shimmer placeholder.
placeholder.animate(onPlay: (c) => c.repeat()).shimmer(duration: 1200.ms);

// Driven by scrolling: progress 0 at offset 0, 1 at offset 300.
header.animate(adapter: ScrollAdapter(scrollController, end: 300)).fadeOut(begin: 1);

// Restart by changing the key.
widget.animate(key: ValueKey(runId)).fadeIn();
```

Run `example/` for a live demo of every effect (`cd example && flutter run`).

### Timing rules

| Case | Start time of an effect |
|---|---|
| no `delay` | same start time as the previous effect |
| `delay: d` | current baseline + `d` (baseline is 0 until the first `then()`) |
| after `then(delay: d)` | end of the previous effect + `d` becomes the new baseline |

`duration` and `curve` are always inherited from the previous effect when omitted, and a
`then(duration:, curve:)` sets them for the effects that follow. The total length of an
`Animate` is the latest end time of any effect.

### Lifecycle

- **Restarts** happen only when the `key` changes, when the chain's timing changes (effect
  types, delays or durations) or when the `controller` changes. Rebuilding with new values
  (`begin`, `end`, colours or builders) updates the output in place without restarting.
- **`target`**: every change animates from the current position. `delay` applies to each
  change, and a newer change cancels one that is still waiting. With `autoPlay: false`, the
  first target is applied without animating.
- **`value`**: sets the start position, and jumps to the new position when it changes.
- **Callbacks**: `onComplete` fires exactly once per completion. `onPlay` always runs before
  `onComplete`, even for zero-length animations. A callback that would otherwise run during a
  build (for example, a zero-length animation or reduced motion) is deferred to the end of the
  frame, so calling `setState` in it is safe.
- **Reduced motion**: when `MediaQuery.disableAnimations` is true, delays are skipped and the
  widget shows the end state (or `target`) immediately. `onComplete` still fires; `onPlay` does
  not, so loops started in `onPlay` stay off. Turn this off with
  `animate(respectReducedMotion: false)` or `Animate.defaultRespectReducedMotion = false`.
  Adapters keep working, because the user drives them.
- **Hot reload**: set `Animate.restartOnHotReload = true` to replay every animation on reload.

### Writing an effect

```dart
class SkewEffect extends Effect<double> {
  const SkewEffect({super.delay, super.duration, super.curve, super.begin = 0.3, super.end = 0});

  @override
  Widget build(BuildContext context, Widget child, AnimationController controller, EffectEntry entry) {
    final skew = buildAnimation(controller, entry); // listener-free, nothing to dispose
    return AnimatedBuilder(
      animation: skew,
      child: child,
      builder: (_, child) => Transform(transform: Matrix4.skewX(skew.value), child: child),
    );
  }
}

box.animate().addEffect(const SkewEffect());
```

## Coming from flutter_animate (migrating)

The class and method names follow flutter_animate, so most code needs only a new import.
This package is a clean-room implementation: it was written from flutter_animate's public API and
documented behaviour, not from its source. It covers a **core subset** of that API. The table lists
what is supported.

| flutter_animate API | animate_chain | Notes |
|---|---|---|
| `Animate(...)`, `widget.animate(...)` | Supported | Same parameters: `key`, `effects`, `onInit`, `onPlay`, `onComplete`, `autoPlay`, `delay`, `controller`, `adapter`, `target`, `value`. Adds `respectReducedMotion`. |
| `then()` / `ThenEffect` | Supported | Same timing rules. |
| Inherited `delay` / `duration` / `curve` | Supported | Same rules. |
| `Animate.defaultDuration`, `Animate.defaultCurve`, `Animate.restartOnHotReload` | Supported | |
| `fade`, `fadeIn`, `fadeOut` | Supported | |
| `slide`, `slideX`, `slideY` | Supported | |
| `move`, `moveX`, `moveY` | Supported | |
| `scale`, `scaleX`, `scaleY`, `scaleXY` | Supported | |
| `rotate` | Supported | |
| `flip`, `flipH`, `flipV` | Supported | |
| `blur`, `blurX`, `blurY`, `blurXY` | Supported | The sigma is clamped at 0, so overshooting curves are safe. |
| `tint`, `untint` | Supported | |
| `color` | Supported | The default colour differs. |
| `shimmer` | Supported | No `padding` parameter, and no padding is added, so the child's size is unchanged. |
| `shake`, `shakeX`, `shakeY` | Supported | The cycle count is rounded so the child always comes to rest in place (at least 1 cycle). |
| `saturate`, `desaturate` | Supported | |
| `custom` | Supported | |
| `visibility`, `show`, `hide` | Supported | |
| `callback` | Supported | |
| `listen` | Supported | No `clamp` parameter; the callback fires only while the effect is progressing. |
| `swap` | Supported | |
| `toggle` | Supported | |
| `AnimateList`, `list.animate(interval:)` | Supported | Only `Spacer` children are skipped (there is no `ignoreTypes`). |
| `ScrollAdapter` | Supported | `begin` and `end` are absolute pixel offsets. |
| `ValueNotifierAdapter`, `ChangeNotifierAdapter` | Supported | `animated` is supported. |
| `300.ms`, `.milliseconds`, `.seconds`, `.minutes` | Supported | |
| `.microseconds`, `.hours`, `.days` | Not supported | Use `Duration(...)`. |
| `AnimateManager` | Renamed | It is called `EffectChain`. |
| `Effect<T>`, `EffectEntry` | Supported | Same `build(context, child, controller, entry)` signature. |
| `EffectList` | Not supported | Use a `List<Effect<Object?>>`. |
| `effect()` (empty effect) | Not supported | |
| `Animate.reparentTypes` (`Flexible` / `Positioned` / `Expanded`) | Not supported | Put `Expanded` / `Positioned` outside the animated widget. |
| `Adapter.direction`, `ValueAdapter` | Not supported | |
| `align`, `boxShadow`, `elevation`, `crossfade`, `followPath`, `shader` effects | Not supported | Use `custom()`. |
| `AnimationController.loop()` extension | Not supported | Use `repeat()`. |
| Offset `copyWith` extensions | Not supported | |

Behaviour that changed on purpose:

| Situation | flutter_animate 4.5.2 | animate_chain |
|---|---|---|
| Widget removed during `delay` | The pending `Future` still runs and calls `forward()` on a disposed controller ([#145](https://github.com/gskinner/flutter_animate/issues/145), [#161](https://github.com/gskinner/flutter_animate/pull/161)). Tests report pending timers ([#151](https://github.com/gskinner/flutter_animate/pull/151)). | A cancellable `Timer`, cancelled on dispose. |
| External `controller` and rebuilds that change timing | A status listener is added on each re-init and never removed, so `onComplete` fires several times and keeps firing after dispose. | One listener, removed on controller change and on dispose. `onComplete` fires once. |
| `onComplete` on a zero-length animation | Fires before `onPlay` ([#152](https://github.com/gskinner/flutter_animate/issues/152)). | `onPlay` fires first. |
| `delay: 0` | One frame of the start state ([#163](https://github.com/gskinner/flutter_animate/issues/163)). | Starts in the same frame. |
| `target` changes with a `delay` | The delay applies only to the first play ([#144](https://github.com/gskinner/flutter_animate/issues/144)). | The delay applies to every change, and a newer change cancels one that is still waiting. |
| `autoPlay: false` with `target` | Still animates to the target on mount ([#89](https://github.com/gskinner/flutter_animate/issues/89)). | Jumps to the target. |
| Effects restart when | the total duration changes | the timing of any effect changes (type, delay or duration) |
| Curved sub-animations | A `CurvedAnimation` is created on every build and never disposed ([#155](https://github.com/gskinner/flutter_animate/issues/155)). | A listener-free view of the controller, with nothing to dispose. |
| `callback`, `listen`, `visibility`, `toggle` | Listeners are added on every build and never removed. | Stateful listeners, removed on dispose. |
| Shimmer | A `ShaderMask` is rebuilt every frame, 0.5 px of padding is added ([#101](https://github.com/gskinner/flutter_animate/issues/101)), and the child is repainted. | One `ShaderMaskLayer`, repainted without any rebuild. The child is cached behind a `RepaintBoundary`, and no padding is added. |
| `MediaQuery.disableAnimations` | Ignored. | Jumps to the end state. |

## Limitations

- This is a core subset. The effects and helpers marked "Not supported" above are left out on
  purpose.
- A delay is a timer. It does not keep the ticker running, but a looping animation with long
  internal effect delays still ticks for its whole duration ([#105](https://github.com/gskinner/flutter_animate/issues/105)
  describes the same cost).
- Sharing one external `AnimationController` between several `Animate`s with different total
  durations is not supported: each one sets the controller's `duration`.
- `callback` works reliably for time-driven playback and for adapters. If you set the
  controller's value by hand while it is animating, crossings in the same tick may be missed.
- Only tested on Flutter 3.35 / Dart 3.9. The declared lower bound (Flutter 3.24) was not
  tested.

## License

MIT. See [LICENSE](LICENSE).

Made by [Abdeldjalil Chougui](https://abdeldjalilchougui.biz/).
