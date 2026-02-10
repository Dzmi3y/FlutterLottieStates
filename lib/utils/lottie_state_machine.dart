import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class LottieAnimationState<T extends Enum> {
  final T id;
  final int startFrame;
  final int endFrame;
  final bool isLoop;
  final T? nextStateId;

  const LottieAnimationState({
    required this.id,
    required this.startFrame,
    required this.endFrame,
    this.nextStateId,
    this.isLoop = false,
  });
}

class LottieAnimationData<T extends Enum> {
  final String src;
  final Map<T, LottieAnimationState<T>> states;

  const LottieAnimationData({required this.src, required this.states});
}

class LottieAnimationStateMachine<T extends Enum> {
  LottieAnimationStateMachine({
    required this.animation,
    required this.currentStateId,
    required this.controller,
  });

  LottieComposition? _composition;
  final AnimationController controller;
  final LottieAnimationData<T> animation;
  T currentStateId;
  LottieAnimationState<T>? get currentState {
    return animation.states[currentStateId];
  }

  Future<({T? nextStateId})> changeState(T newState) async {
    currentStateId = newState;

    final state = currentState;
    final comp = _composition;

    if (comp == null || state == null) return (nextStateId: null);

    double frame(int f) => (f / comp.durationFrames).clamp(0.0, 1.0);

    if (state.isLoop) {
      await controller.repeat(
        min: frame(state.startFrame),
        max: frame(state.endFrame),
      );
      return (nextStateId: state.nextStateId);
    } else {
      controller.value = frame(state.startFrame);
      await controller.animateTo(frame(state.endFrame));
      return (nextStateId: state.nextStateId);
    }
  }

  void loadedHandler(LottieComposition composition) {
    _composition = composition;
    controller.duration = composition.duration;
    changeState(currentStateId);
  }

  LottieBuilder buildLottie ({double? height = 400, double? width = 400, BoxFit? fit = BoxFit.cover}) {
    return Lottie.asset(
      animation.src,
      controller: controller,
      height: height,
      width: width,
      fit: fit,
      onLoaded: loadedHandler,
    );
  }
}
