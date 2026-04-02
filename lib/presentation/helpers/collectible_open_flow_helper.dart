import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'opening_roll_sequence_builder.dart';
import '../widgets/opening_roller.dart';

class CollectibleOpenFlowHelper {
  const CollectibleOpenFlowHelper._();

  static Future<void> runReveal<TDrop>({
    required void Function(VoidCallback fn) setState,
    required bool Function() isMounted,
    required bool isOpening,
    required bool hasItems,
    required void Function() onStart,
    required TDrop Function() resolveDrop,
    required void Function(TDrop drop) onComplete,
    required Random random,
    int baseDelayMs = 1200,
    int randomDelayMs = 800,
  }) async {
    if (isOpening || !hasItems) return;

    setState(onStart);

    await Future.delayed(
      Duration(milliseconds: baseDelayMs + random.nextInt(randomDelayMs)),
    );

    final drop = resolveDrop();
    if (!isMounted()) return;

    setState(() => onComplete(drop));
  }

  static Future<void> runRoulette<TItem, TDrop>({
    required void Function(VoidCallback fn) setState,
    required bool Function() isMounted,
    required bool isOpening,
    required bool hasItems,
    required ScrollController controller,
    required OpeningRollSequenceData<TItem> rollData,
    required TDrop drop,
    required void Function(OpeningRollSequenceData<TItem> rollData) onStart,
    required void Function(TDrop drop) onComplete,
    Duration rollDuration = const Duration(milliseconds: 6800),
    Duration revealDelay = const Duration(milliseconds: 200),
  }) async {
    if (isOpening || !hasItems) return;

    setState(() => onStart(rollData));

    await _waitForRollLayout(controller);
    if (!controller.hasClients) return;

    controller.jumpTo(0);

    await _waitForRollLayout(controller);
    if (!controller.hasClients) return;

    final viewportWidth = controller.position.viewportDimension;
    final itemWidth = OpeningRollLayout.rollItemWidth(viewportWidth);
    final targetOffset = OpeningRollLayout.computeTargetOffset(
      winningIndex: rollData.winnerIndex,
      viewportWidth: viewportWidth,
      itemWidth: itemWidth,
      maxScrollExtent: controller.position.maxScrollExtent,
    );

    await controller.animateTo(
      targetOffset,
      duration: rollDuration,
      curve: Curves.easeOutQuart,
    );

    await Future.delayed(revealDelay);
    if (!isMounted()) return;

    setState(() => onComplete(drop));
  }

  static Future<void> _waitForRollLayout(ScrollController controller) async {
    for (int i = 0; i < 6; i++) {
      await SchedulerBinding.instance.endOfFrame;
      if (controller.hasClients &&
          controller.position.hasContentDimensions &&
          controller.position.maxScrollExtent > 0) {
        return;
      }
    }
  }
}
