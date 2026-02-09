import 'dart:async';
import 'package:shake/shake.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:vibration/vibration.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

void main() {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  runApp(const MyApp());
  Future.delayed(const Duration(seconds: 1), () {
    FlutterNativeSplash.remove();
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Shake Demo',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
      home: const MyHomePage(title: 'Shake'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

enum AnimationStatus { idle, preShake, shake, postShake }

class _MyHomePageState extends State<MyHomePage> with TickerProviderStateMixin {
  late final AnimationController _controller;
  LottieComposition? _composition;
  Timer? _stopTimer;
  bool _isShaking = false;
  late ShakeDetector detector;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);

    detector = ShakeDetector.autoStart(
      onPhoneShake: (ShakeEvent event) {
        _handleShake();
      },
      shakeThresholdGravity: 2.7,
    );
  }

  void _handleShake() {
    if (!_isShaking) {
      setState(() => _isShaking = true);
      Vibration.vibrate(duration: 5000);
      _changeAnimation(AnimationStatus.preShake);
    }
    _stopTimer?.cancel();
    _stopTimer = Timer(const Duration(milliseconds: 800), () {
      Vibration.cancel();
      if (mounted) {
        setState(() => _isShaking = false);
        _changeAnimation(AnimationStatus.postShake);
      }
    });
  }

  void _changeAnimation(AnimationStatus status) {
    if (_composition == null) return;

    double frame(int f) => (f / _composition!.durationFrames).clamp(0.0, 1.0);

    switch (status) {
      case AnimationStatus.idle:
        _controller.repeat(min: frame(150), max: frame(240));
        break;
      case AnimationStatus.preShake:
        _controller.value = frame(0);
        _controller.animateTo(frame(30)).then((_) {
          if (_isShaking && mounted) _changeAnimation(AnimationStatus.shake);
        });
        break;
      case AnimationStatus.shake:
        _controller.repeat(min: frame(60), max: frame(90));
        break;
      case AnimationStatus.postShake:
        _controller.value = frame(90);
        _controller.animateTo(frame(150)).then((_) {
          if (!_isShaking && mounted) _changeAnimation(AnimationStatus.idle);
        });
        break;
    }
  }

  @override
  void dispose() {
    detector.stopListening();
    _stopTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color backgroundColor = _isShaking ? Colors.green.shade100 : Colors.blue.shade100;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(widget.title),
        centerTitle: true,
        elevation: 2,
        backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
      ),
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        color: backgroundColor,
        child: Center(
          child: Lottie.asset(
            'assets/animations/RhvlShake.json',
            controller: _controller,
            height: 400,
            width: 400,
            fit: BoxFit.cover,
            onLoaded: (composition) {
              _composition = composition;
              _controller.duration = composition.duration;
              _changeAnimation(AnimationStatus.idle);
            },
          ),
        ),
      ),
    );
  }
}
