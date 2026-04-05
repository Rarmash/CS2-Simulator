import 'package:flutter/material.dart';

import '../../data/models/skin_dto.dart';
import '../../data/repositories/local_data_repository.dart';
import '../../domain/dropped_skin.dart';
import '../../domain/tradeup_service.dart';
import '../helpers/responsive_grid_helper.dart';
import '../helpers/tradeup_controller.dart';
import '../widgets/tradeup_chance_card.dart';
import '../widgets/skin_drop_card.dart';
import '../widgets/tradeup_selected_slot.dart';
import '../widgets/tradeup_skin_tile.dart';

class TradeUpScreen extends StatefulWidget {
  final LocalDataRepository repository;

  const TradeUpScreen({super.key, required this.repository});

  @override
  State<TradeUpScreen> createState() => _TradeUpScreenState();
}

class _TradeUpScreenState extends State<TradeUpScreen> {
  static const double _tradeupPanelMaxWidth = 620;

  late Future<_TradeUpData> _dataFuture;

  late final TradeUpController _controller;

  String _search = '';
  String? _rarity = 'MIL_SPEC';

  @override
  void initState() {
    super.initState();
    _controller = TradeUpController(service: TradeUpService());
    _dataFuture = _loadData();
  }

  Future<_TradeUpData> _loadData() async {
    final skins = await widget.repository.loadSkins();
    final containers = await widget.repository.loadContainers();
    final containerToSkinIds = await widget.repository.loadContainerToSkinIds();

    final regularContainers = {
      for (final c in containers.where((c) => c.isRegularCase)) c.id: c,
    };

    final skinIdToRegularCaseIds = <String, List<String>>{};
    final regularCaseIdToSkinIds = <String, List<String>>{};

    for (final entry in containerToSkinIds.entries) {
      final containerId = entry.key;
      final isRegularCase = regularContainers.containsKey(containerId);

      if (isRegularCase) {
        regularCaseIdToSkinIds[containerId] = List<String>.from(entry.value);
      }

      for (final skinId in entry.value) {
        if (isRegularCase) {
          skinIdToRegularCaseIds.putIfAbsent(skinId, () => []).add(containerId);
        }
      }
    }

    return _TradeUpData(
      skins: skins,
      skinIdToRegularCaseIds: skinIdToRegularCaseIds,
      regularCaseIdToSkinIds: regularCaseIdToSkinIds,
    );
  }

  String _rarityLabel(String rarity) {
    switch (rarity) {
      case 'CONSUMER':
        return 'Consumer';
      case 'INDUSTRIAL':
        return 'Industrial';
      case 'MIL_SPEC':
        return 'Mil-Spec';
      case 'RESTRICTED':
        return 'Restricted';
      case 'CLASSIFIED':
        return 'Classified';
      case 'COVERT':
        return 'Covert';
      default:
        return rarity;
    }
  }

  int _maxSelectable() {
    return _controller.maxSelectable();
  }

  bool _canAddMore() {
    return _controller.canAddMore;
  }

  bool _canExecuteTrade() {
    return _controller.canExecuteTrade;
  }

  void _add(SkinDto skin, _TradeUpData data) {
    try {
      _controller.add(
        skin,
        allSkins: data.skins,
        skinIdToRegularCaseIds: data.skinIdToRegularCaseIds,
        regularCaseIdToSkinIds: data.regularCaseIdToSkinIds,
      );
      setState(() {});
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  Future<void> _editFloatAt(int index, _TradeUpData data) async {
    final item = _controller.selected[index];
    final controller = TextEditingController(
      text: item.floatValue.toStringAsFixed(5),
    );
    var selectedQuality = item.quality;

    final result = await showDialog<double>(
      context: context,
      builder: (context) {
        String? errorText;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Set Float'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.skin.itemDisplayName),
                  Text(
                    item.skin.name,
                    style: const TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Allowed range: ${item.skin.floatTop.toStringAsFixed(2)} - ${item.skin.floatBottom.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: controller,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Float value',
                      errorText: errorText,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Quality mode',
                    style: TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      for (final quality in _editableQualities)
                        ChoiceChip(
                          label: Text(_qualityLabel(quality)),
                          selected: selectedQuality == quality,
                          onSelected: (_) {
                            setDialogState(() {
                              selectedQuality = quality;
                            });
                          },
                        ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    final parsed = double.tryParse(
                      controller.text.trim().replaceAll(',', '.'),
                    );

                    if (parsed == null) {
                      setDialogState(() {
                        errorText = 'Enter a valid float value';
                      });
                      return;
                    }

                    if (parsed < item.skin.floatTop ||
                        parsed > item.skin.floatBottom) {
                      setDialogState(() {
                        errorText = 'Float must stay within the allowed range';
                      });
                      return;
                    }

                    Navigator.of(context).pop(parsed);
                  },
                  child: const Text('Apply'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == null) return;

    setState(() {
      _controller.updateItem(
        index,
        floatValue: result,
        quality: selectedQuality,
        allSkins: data.skins,
        skinIdToRegularCaseIds: data.skinIdToRegularCaseIds,
        regularCaseIdToSkinIds: data.regularCaseIdToSkinIds,
      );
    });
  }

  void _removeAt(int index, _TradeUpData data) {
    setState(() {
      _controller.removeAt(
        index,
        allSkins: data.skins,
        skinIdToRegularCaseIds: data.skinIdToRegularCaseIds,
        regularCaseIdToSkinIds: data.regularCaseIdToSkinIds,
      );
      if (_controller.selected.isEmpty) {
        _rarity = 'MIL_SPEC';
      }
    });
  }

  void _clear() {
    setState(() {
      _controller.clear();
    });
  }

  Future<void> _trade(_TradeUpData data) async {
    try {
      _controller.executeTrade(
        allSkins: data.skins,
        skinIdToRegularCaseIds: data.skinIdToRegularCaseIds,
        regularCaseIdToSkinIds: data.regularCaseIdToSkinIds,
      );
      setState(() {
        // Controller already updated its state.
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  bool _matchesSearch(SkinDto skin) {
    final q = _search.trim().toLowerCase();
    if (q.isEmpty) return true;

    final collection = (skin.collection ?? '').toLowerCase();

    return skin.name.toLowerCase().contains(q) ||
        skin.itemDisplayName.toLowerCase().contains(q) ||
        collection.contains(q);
  }

  String _qualityLabel(TradeUpInputQuality quality) {
    switch (quality) {
      case TradeUpInputQuality.regular:
        return 'Regular';
      case TradeUpInputQuality.statTrak:
        return 'StatTrak™';
      case TradeUpInputQuality.souvenir:
        return 'Souvenir';
    }
  }

  List<TradeUpInputQuality> get _editableQualities => const [
    TradeUpInputQuality.regular,
    TradeUpInputQuality.statTrak,
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Trade-Up Simulator')),
      body: FutureBuilder<_TradeUpData>(
        future: _dataFuture,
        builder: (_, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snap.data!;
          final filtered = data.skins.where((skin) {
            if (skin.isSpecialItem) return false;

            const allowedRarities = {
              'CONSUMER',
              'INDUSTRIAL',
              'MIL_SPEC',
              'RESTRICTED',
              'CLASSIFIED',
              'COVERT',
            };

            if (!allowedRarities.contains(skin.rarity)) {
              return false;
            }

            if (_rarity != null && skin.rarity != _rarity) {
              return false;
            }

            return _matchesSearch(skin);
          }).toList();

          filtered.sort((a, b) => int.parse(a.id).compareTo(int.parse(b.id)));

          return LayoutBuilder(
            builder: (context, constraints) {
              return CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextField(
                            decoration: const InputDecoration(
                              hintText: 'Search by skin or collection...',
                              prefixIcon: Icon(Icons.search),
                            ),
                            onChanged: (value) => setState(() => _search = value),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            children: [
                              for (final rarity in [
                                'CONSUMER',
                                'INDUSTRIAL',
                                'MIL_SPEC',
                                'RESTRICTED',
                                'CLASSIFIED',
                                'COVERT',
                              ])
                                ChoiceChip(
                                  label: Text(_rarityLabel(rarity)),
                                  selected: _rarity == rarity,
                                  onSelected: (_) {
                                    setState(() {
                                      _rarity = rarity;
                                      _clear();
                                    });
                                  },
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _controller.selected.isEmpty
                                ? 'Select skins'
                                : 'Selected: ${_controller.selected.length}/${_maxSelectable()}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (_controller.selected.isNotEmpty)
                            const Padding(
                              padding: EdgeInsets.only(top: 4),
                              child: Text(
                                'Tap a selected skin to edit its float',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          if (_controller.selected.isNotEmpty &&
                              _controller.selected.first.skin.rarity == 'COVERT')
                            const Padding(
                              padding: EdgeInsets.only(top: 4),
                              child: Text(
                                'Covert trade-up uses exactly 5 skins',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          if (!_canAddMore())
                            const Padding(
                              padding: EdgeInsets.only(top: 4),
                              child: Text(
                                'Selection is full',
                                style: TextStyle(
                                  color: Colors.amber,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          if (_controller.tradeIssue != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                _controller.tradeIssue!,
                                style: const TextStyle(
                                  color: Colors.orangeAccent,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxWidth: _tradeupPanelMaxWidth,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: 10,
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 5,
                                  crossAxisSpacing: 6,
                                  mainAxisSpacing: 6,
                                ),
                            itemBuilder: (_, index) => TradeUpSelectedSlot(
                              item: index < _controller.selected.length
                                  ? _controller.selected[index]
                                  : null,
                              onTap: index < _controller.selected.length
                                  ? () => _editFloatAt(index, data)
                                  : null,
                              onRemove: index < _controller.selected.length
                                  ? () => _removeAt(index, data)
                                  : null,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxWidth: _tradeupPanelMaxWidth,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: _canExecuteTrade()
                                      ? () => _trade(data)
                                      : null,
                                  child: Text(
                                    _controller.selected.isNotEmpty &&
                                            _controller.selected.first.skin.rarity ==
                                                'COVERT'
                                        ? 'TRADE SPECIAL ITEM'
                                        : 'TRADE',
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              OutlinedButton(
                                onPressed: _controller.selected.isNotEmpty
                                    ? _clear
                                    : null,
                                child: const Text('CLEAR'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxWidth: _tradeupPanelMaxWidth,
                        ),
                        child: _controller.result == null
                            ? const SizedBox()
                            : SkinDropCard(
                                drop: DroppedSkin(
                                  skin: _controller.result!.skin,
                                  isStatTrak: _controller.result!.isStatTrak,
                                  isSouvenir: _controller.result!.isSouvenir,
                                  skinFloat: _controller.result!.floatValue,
                                  exterior: _controller.result!.exterior,
                                ),
                              ),
                      ),
                    ),
                  ),
                  if (_controller.chances.isNotEmpty)
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(12, 12, 12, 8),
                        child: Text(
                          'Possible results with projected float',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  if (_controller.chances.isNotEmpty)
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      sliver: SliverGrid(
                        delegate: SliverChildBuilderDelegate(
                          (_, index) => TradeUpChanceCard(
                            chance: _controller.chances[index],
                          ),
                          childCount: _controller.chances.length,
                        ),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount:
                              ResponsiveGridHelper.tradeGridCrossAxisCount(
                                constraints.maxWidth,
                              ),
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                          childAspectRatio: 0.72,
                        ),
                      ),
                    ),
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(12, 12, 12, 8),
                      child: Text(
                        'Available skins',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.all(12),
                    sliver: SliverGrid(
                      delegate: SliverChildBuilderDelegate(
                        (_, index) => TradeUpSkinTile(
                          skin: filtered[index],
                          selectedCount: _controller.selected
                              .where((e) => e.skin.id == filtered[index].id)
                              .length,
                          blocked: !_canAddMore(),
                          onTap: () => _add(filtered[index], data),
                        ),
                        childCount: filtered.length,
                      ),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount:
                            ResponsiveGridHelper.tradeGridCrossAxisCount(
                              constraints.maxWidth,
                            ),
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                        childAspectRatio: 0.75,
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _TradeUpData {
  final List<SkinDto> skins;
  final Map<String, List<String>> skinIdToRegularCaseIds;
  final Map<String, List<String>> regularCaseIdToSkinIds;

  const _TradeUpData({
    required this.skins,
    required this.skinIdToRegularCaseIds,
    required this.regularCaseIdToSkinIds,
  });
}
