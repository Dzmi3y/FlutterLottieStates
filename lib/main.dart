import 'dart:async';
import 'package:flutter_application_1/utils/lottie_state_machine.dart';
import 'package:shake/shake.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:vibration/vibration.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

void main() {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  runApp(const MyApp());
  FlutterNativeSplash.remove();
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
  late final LottieAnimationStateMachine _stateMachine;

  final _animationData = const LottieAnimationData(
    src: 'assets/animations/RhvlShake.json',
    states: {
      AnimationStatus.idle: LottieAnimationState<AnimationStatus>(
        id: AnimationStatus.idle,
        startFrame: 150,
        endFrame: 240,
        isLoop: true,
      ),
      AnimationStatus.preShake: LottieAnimationState<AnimationStatus>(
        id: AnimationStatus.preShake,
        startFrame: 0,
        endFrame: 30,
        nextStateId: AnimationStatus.shake,
        isLoop: false,
      ),
      AnimationStatus.shake: LottieAnimationState<AnimationStatus>(
        id: AnimationStatus.shake,
        startFrame: 60,
        endFrame: 90,
        isLoop: true,
      ),
      AnimationStatus.postShake: LottieAnimationState<AnimationStatus>(
        id: AnimationStatus.postShake,
        startFrame: 90,
        endFrame: 150,
        nextStateId: AnimationStatus.idle,
        isLoop: false,
      ),
    },
  );

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
    _stateMachine = LottieAnimationStateMachine<AnimationStatus>(
      controller: _controller,
      currentStateId: AnimationStatus.idle,
      animation: _animationData,
    );
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
    _stateMachine
        .changeState(status)
        .then(
          (value) => {
            if (_isShaking && mounted && value.nextStateId != null)
              {_changeAnimation(value.nextStateId as AnimationStatus)},
          },
        );
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
    final Color backgroundColor = _isShaking
        ? Colors.green.shade100
        : Colors.blue.shade100;

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
        child: Center(child: _stateMachine.buildLottie()),
      ),
    );
  }
}
