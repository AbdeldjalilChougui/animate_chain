import 'package:animate_chain/animate_chain.dart';
import 'package:flutter/material.dart';

void main() => runApp(const DemoApp());

/// Demo app: one card per effect, plus stagger, target, adapters.
class DemoApp extends StatelessWidget {
  /// Creates the demo app.
  const DemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'animate_chain',
      theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
      home: const DemoPage(),
    );
  }
}

/// The list of demos.
class DemoPage extends StatefulWidget {
  /// Creates the demo page.
  const DemoPage({super.key});

  @override
  State<DemoPage> createState() => _DemoPageState();
}

class _DemoPageState extends State<DemoPage> {
  // Bumping this key restarts every one-shot demo.
  int _run = 0;
  bool _selected = false;
  final _slider = ValueNotifier<double>(0.5);
  final _scroll = ScrollController();

  @override
  void dispose() {
    _slider.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final key = ValueKey(_run);
    final demos = <(String, Widget)>[
      ('fadeIn', _Tile.icon.animate(key: key).fadeIn(duration: 600.ms)),
      ('fadeOut', _Tile.icon.animate(key: key).fadeOut(duration: 600.ms)),
      (
        'slideX / slideY',
        _Tile.icon.animate(key: key).slideX(begin: -1).slideY(begin: 1)
      ),
      ('move', _Tile.icon.animate(key: key).move(begin: const Offset(-40, 0))),
      (
        'scale / scaleXY',
        _Tile.icon
            .animate(key: key)
            .scaleXY(curve: Curves.elasticOut, duration: 900.ms)
      ),
      (
        'rotate',
        _Tile.icon
            .animate(key: key)
            .rotate(duration: 800.ms, curve: Curves.easeOutBack)
      ),
      (
        'flip',
        _Tile.icon.animate(key: key).flipH(begin: -0.5, duration: 700.ms)
      ),
      (
        'blur',
        _Tile.icon.animate(key: key).blurXY(begin: 10, end: 0, duration: 800.ms)
      ),
      (
        'tint',
        _Tile.icon
            .animate(key: key)
            .tint(color: Colors.orange, end: 0.8, duration: 800.ms)
      ),
      (
        'color',
        _Tile.icon
            .animate(key: key)
            .color(end: Colors.green, blendMode: BlendMode.modulate)
      ),
      ('saturate', _Tile.photo.animate(key: key).saturate(duration: 1.seconds)),
      ('shake', _Tile.icon.animate(key: key).shakeX(duration: 600.ms)),
      (
        'shimmer (looping)',
        _Tile.bar.animate(onPlay: (c) => c.repeat()).shimmer(duration: 1200.ms)
      ),
      (
        'then()',
        _Tile.icon
            .animate(key: key)
            .fadeIn(duration: 300.ms)
            .then(delay: 200.ms)
            .scaleXY(begin: 1, end: 1.4, duration: 250.ms)
            .then()
            .scaleXY(begin: 1, end: 1 / 1.4),
      ),
      (
        'custom',
        Animate(key: key).custom(
          duration: 1.seconds,
          end: 100,
          builder: (context, value, _) => Text('${value.round()} %'),
        ),
      ),
      ('visibility (show)', _Tile.icon.animate(key: key).show(delay: 500.ms)),
      (
        'callback',
        _Tile.icon.animate(key: key).fadeIn(duration: 600.ms).callback(
              callback: (_) => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('callback fired')),
              ),
            ),
      ),
      (
        'listen',
        _ListenDemo(key: key),
      ),
      (
        'swap',
        const Text('Before')
            .animate(key: key)
            .fadeOut(delay: 600.ms, duration: 300.ms)
            .swap(builder: (_, __) => const Text('After').animate().fadeIn()),
      ),
      (
        'toggle',
        Animate(key: key).toggle(
          duration: 700.ms,
          builder: (_, before, __) => AnimatedContainer(
            duration: 400.ms,
            width: before ? 40 : 120,
            height: 40,
            color: before ? Colors.red : Colors.teal,
          ),
        ),
      ),
      (
        'target (tap me)',
        GestureDetector(
          onTap: () => setState(() => _selected = !_selected),
          child: _Tile.icon
              .animate(target: _selected ? 1 : 0)
              .scaleXY(begin: 1, end: 1.3, duration: 200.ms)
              .tint(color: Colors.indigo, end: 0.6),
        ),
      ),
      (
        'ValueNotifierAdapter',
        Column(
          children: [
            _Tile.icon
                .animate(adapter: ValueNotifierAdapter(_slider))
                .rotate(begin: 0, end: 1),
            ValueListenableBuilder<double>(
              valueListenable: _slider,
              builder: (_, v, __) => Slider(
                value: v,
                onChanged: (x) => _slider.value = x,
              ),
            ),
          ],
        ),
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('animate_chain')
            .animate(adapter: ScrollAdapter(_scroll, end: 400))
            .fade(begin: 1, end: 0.3),
        actions: [
          IconButton(
            tooltip: 'Replay',
            icon: const Icon(Icons.replay),
            onPressed: () => setState(() => _run++),
          ),
        ],
      ),
      body: ListView(
        controller: _scroll,
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Staggered list',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Row(
            key: key,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [for (var i = 0; i < 6; i++) _Tile.dot]
                .animate(interval: 100.ms)
                .fadeIn(duration: 300.ms)
                .moveY(begin: 20, curve: Curves.easeOutCubic),
          ),
          const SizedBox(height: 16),
          for (final (label, demo) in demos)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(child: Text(label)),
                    SizedBox(
                      width: 160,
                      child: Center(child: demo),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ListenDemo extends StatefulWidget {
  const _ListenDemo({super.key});

  @override
  State<_ListenDemo> createState() => _ListenDemoState();
}

class _ListenDemoState extends State<_ListenDemo> {
  final _value = ValueNotifier<double>(0);

  @override
  void dispose() {
    _value.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _Tile.icon
            .animate()
            .fadeIn(duration: 1.seconds)
            .listen(callback: (v) => _value.value = v),
        ValueListenableBuilder<double>(
          valueListenable: _value,
          builder: (_, v, __) => LinearProgressIndicator(value: v),
        ),
      ],
    );
  }
}

abstract final class _Tile {
  static const Widget icon = Icon(Icons.auto_awesome, size: 40);
  static const Widget dot = CircleAvatar(radius: 16);
  static const Widget photo = SizedBox(
    width: 120,
    height: 40,
    child: DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.red, Colors.yellow, Colors.blue],
        ),
      ),
    ),
  );
  static const Widget bar = SizedBox(
    width: 140,
    height: 24,
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: Color(0xFFBDBDBD),
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
    ),
  );
}
