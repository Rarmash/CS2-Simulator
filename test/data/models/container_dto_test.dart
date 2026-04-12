import 'package:flutter_test/flutter_test.dart';

import '../../test_data_builders.dart';

void main() {
  group('ContainerDto', () {
    test('exposes type flags and labels', () {
      final reward = buildContainer(
        id: '1',
        type: 'REWARD_COLLECTION',
        sourceType: 'ARMORY_REWARD',
        sourceName: 'The Armory',
        currency: 'STARS',
        cost: 2,
      );

      expect(reward.isRewardCollection, isTrue);
      expect(reward.isArmoryRewardCollection, isTrue);
      expect(reward.typeLabel, 'Reward Collection');
      expect(reward.sourceTypeLabel, 'Armory Reward');
      expect(reward.sourceLabel, 'The Armory');
      expect(reward.currencyLabel, 'Stars');
      expect(reward.actionLabel, 'Spend 2 Stars');
    });

    test('builds readable fallback source label from source id', () {
      final container = buildContainer(
        id: '2',
        sourceId: 'BROKEN_FANG',
        sourceName: null,
      );

      expect(container.sourceLabel, 'Broken Fang');
    });
  });
}
