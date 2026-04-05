import 'package:flutter/material.dart';

import '../../data/models/skin_dto.dart';
import '../../data/repositories/local_data_repository.dart';
import '../../domain/skin_float_helper.dart';
import '../../domain/tradeup_service.dart';
import '../helpers/responsive_grid_helper.dart';
import '../helpers/skin_ui_helper.dart';

class TradeUpScreen extends StatefulWidget {
  final LocalDataRepository repository;

  const TradeUpScreen({super.key, required this.repository});

  @override
  State<TradeUpScreen> createState() => _TradeUpScreenState();
}

class _TradeUpScreenState extends State<TradeUpScreen> {
  late Future<_TradeUpData> _dataFuture;

  final TradeUpService _service = TradeUpService();

  final List<TradeUpInputItem> _selected = [];
  TradeUpResult? _result;
  List<TradeUpChance> _chances = [];
  String? _tradeIssue;

  String _search = '';
  String? _rarity = 'MIL_SPEC';

  @override
  void initState() {
    super.initState();
    _dataFuture = _loadData();
  }

  Future<_TradeUpData> _loadData() async {
    final skins = await widget.repository.loadSkins();
    final cases = await widget.repository.loadContainers();
    final caseToSkinIds = await widget.repository.loadContainerToSkinIds();

    final regularCases = {
      for (final c in cases.where((c) => c.isRegularCase)) c.id: c,
    };

    final skinIdToRegularCaseIds = <String, List<String>>{};
    final regularCaseIdToSkinIds = <String, List<String>>{};

    for (final entry in caseToSkinIds.entries) {
      final containerId = entry.key;
      final isRegularCase = regularCases.containsKey(containerId);

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
    if (_selected.isEmpty) return 10;
    return _selected.first.skin.rarity == 'COVERT' ? 5 : 10;
  }

  bool _canAddMore() {
    return _selected.length < _maxSelectable();
  }

  bool _tradeReady() {
    if (_selected.isEmpty) return false;
    final rarity = _selected.first.skin.rarity;

    if (rarity == 'COVERT') {
      return _selected.length == 5;
    }
    return _selected.length == 10;
  }

  bool _canExecuteTrade() {
    return _tradeReady() && _tradeIssue == null;
  }

  void _recalculateChances(_TradeUpData data) {
    _tradeIssue = null;

    if (_tradeReady()) {
      try {
        _chances = _service.getTradeUpChances(
          input: _selected,
          allSkins: data.skins,
          skinIdToRegularCaseIds: data.skinIdToRegularCaseIds,
          regularCaseIdToSkinIds: data.regularCaseIdToSkinIds,
        );

        if (_chances.isEmpty) {
          _tradeIssue = 'This selection cannot produce a valid trade-up result';
        }
      } catch (e) {
        _chances = [];
        _tradeIssue = e.toString().replaceFirst('Exception: ', '');
      }
    } else {
      _chances = [];
    }
  }

  void _add(SkinDto skin, _TradeUpData data) {
    if (!_canAddMore()) return;

    if (_selected.isNotEmpty && _selected.first.skin.rarity != skin.rarity) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All selected skins must have the same rarity'),
        ),
      );
      return;
    }

    setState(() {
      _selected.add(
        TradeUpInputItem(
          skin: skin,
          floatValue: (skin.floatTop + skin.floatBottom) / 2,
        ),
      );
      _result = null;
      _recalculateChances(data);
    });
  }

  Future<void> _editFloatAt(int index, _TradeUpData data) async {
    final item = _selected[index];
    final controller = TextEditingController(
      text: item.floatValue.toStringAsFixed(5),
    );

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
      _selected[index] = TradeUpInputItem(skin: item.skin, floatValue: result);
      _result = null;
      _recalculateChances(data);
    });
  }

  void _removeAt(int index, _TradeUpData data) {
    setState(() {
      _selected.removeAt(index);
      _result = null;
      _recalculateChances(data);

      if (_selected.isEmpty) {
        _rarity = 'MIL_SPEC';
      }
    });
  }

  void _clear() {
    setState(() {
      _selected.clear();
      _result = null;
      _chances = [];
      _tradeIssue = null;
    });
  }

  Future<void> _trade(_TradeUpData data) async {
    try {
      final result = _service.tradeUp(
        input: _selected,
        allSkins: data.skins,
        skinIdToRegularCaseIds: data.skinIdToRegularCaseIds,
        regularCaseIdToSkinIds: data.regularCaseIdToSkinIds,
      );

      setState(() {
        _result = result;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  bool _matchesSearch(SkinDto s) {
    final q = _search.trim().toLowerCase();
    if (q.isEmpty) return true;

    final collection = (s.collection ?? '').toLowerCase();

    return s.name.toLowerCase().contains(q) ||
        s.itemDisplayName.toLowerCase().contains(q) ||
        collection.contains(q);
  }

  Widget _slot(int i, _TradeUpData data) {
    final item = i < _selected.length ? _selected[i] : null;

    if (item == null) {
      return Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white24),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Center(child: Icon(Icons.add)),
      );
    }

    final skin = item.skin;
    final color = SkinUiHelper.rarityColor(skin);

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: color, width: 2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Stack(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => _editFloatAt(i, data),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Column(
                  children: [
                    Expanded(
                      child: Image.asset(
                        skin.skinImage,
                        fit: BoxFit.contain,
                        errorBuilder: (_, error, stackTrace) =>
                            const Icon(Icons.image_not_supported),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'FV ${item.floatValue.toStringAsFixed(5)}',
                      style: const TextStyle(
                        fontSize: 9,
                        color: Colors.white70,
                      ),
                    ),
                    Text(
                      SkinFloatHelper.exteriorFromFloat(item.floatValue),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 8,
                        color: Colors.white54,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            right: 0,
            top: 0,
            child: Material(
              color: Colors.black87,
              borderRadius: BorderRadius.circular(8),
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () => _removeAt(i, data),
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(Icons.close, size: 12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _skinTile(SkinDto s, _TradeUpData data) {
    final color = SkinUiHelper.rarityColor(s);
    final count = _selected.where((e) => e.skin.id == s.id).length;
    final blocked = !_canAddMore();

    return Opacity(
      opacity: blocked ? 0.55 : 1,
      child: GestureDetector(
        onTap: blocked ? null : () => _add(s, data),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white10),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Stack(
            children: [
              Column(
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Image.asset(
                        s.skinImage,
                        fit: BoxFit.contain,
                        errorBuilder: (_, error, stackTrace) =>
                            const Icon(Icons.image_not_supported),
                      ),
                    ),
                  ),
                  Container(height: 3, color: color),
                  Padding(
                    padding: const EdgeInsets.all(5),
                    child: Column(
                      children: [
                        Text(
                          s.itemDisplayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 10),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          s.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.white70,
                          ),
                        ),
                        if (s.collection != null &&
                            s.collection!.isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Text(
                            s.collection!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 9,
                              color: Colors.white38,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              if (count > 0)
                Positioned(
                  right: 4,
                  top: 4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'x$count',
                      style: const TextStyle(fontSize: 10),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _resultCard() {
    if (_result == null) return const SizedBox();

    final s = _result!.skin;
    final color = SkinUiHelper.rarityColor(s);

    return Card(
      margin: const EdgeInsets.all(12),
      shape: RoundedRectangleBorder(
        side: BorderSide(color: color, width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Image.asset(
              s.skinImage,
              height: 120,
              errorBuilder: (_, error, stackTrace) =>
                  const Icon(Icons.image_not_supported, size: 80),
            ),
            const SizedBox(height: 8),
            Text(
              '${s.isSpecialItem ? 'РІВвЂ¦ ' : ''}${s.itemDisplayName} | ${s.name}',
              style: TextStyle(color: color, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              'Rarity: ${s.isSpecialItem ? 'Special Item' : _rarityLabel(s.rarity)}',
            ),
            Text('Weapon type: ${SkinUiHelper.weaponTypeLabel(s.weaponType)}'),
            Text('Float: ${_result!.floatValue.toStringAsFixed(5)}'),
            Text(_result!.exterior),
          ],
        ),
      ),
    );
  }

  Widget _chanceCard(TradeUpChance chance) {
    final skin = chance.skin;
    final color = SkinUiHelper.rarityColor(skin);

    return Card(
      margin: EdgeInsets.zero,
      child: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Image.asset(
                skin.skinImage,
                fit: BoxFit.contain,
                errorBuilder: (_, error, stackTrace) =>
                    const Icon(Icons.image_not_supported),
              ),
            ),
          ),
          Container(height: 3, color: color),
          Padding(
            padding: const EdgeInsets.all(6),
            child: Column(
              children: [
                Text(
                  skin.itemDisplayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 10),
                ),
                const SizedBox(height: 3),
                Text(
                  skin.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 10, color: Colors.white70),
                ),
                const SizedBox(height: 4),
                Text(
                  '${(chance.probability * 100).toStringAsFixed(2)}%',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  chance.exterior,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 9,
                    color: Colors.white70,
                  ),
                ),
                Text(
                  'FV ${chance.floatValue.toStringAsFixed(5)}',
                  style: const TextStyle(
                    fontSize: 9,
                    color: Colors.white54,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

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
          final all = data.skins;

          final filtered = all.where((s) {
            if (s.isSpecialItem) return false;

            const allowedRarities = {
              'CONSUMER',
              'INDUSTRIAL',
              'MIL_SPEC',
              'RESTRICTED',
              'CLASSIFIED',
              'COVERT',
            };

            if (!allowedRarities.contains(s.rarity)) {
              return false;
            }

            if (_rarity != null && s.rarity != _rarity) {
              return false;
            }

            return _matchesSearch(s);
          }).toList();

          filtered.sort((a, b) => int.parse(a.id).compareTo(int.parse(b.id)));

          return LayoutBuilder(
            builder: (context, c) {
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
                              hintText:
                                  'Search by skin or collection...',
                              prefixIcon: Icon(Icons.search),
                            ),
                            onChanged: (v) => setState(() => _search = v),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            children: [
                              for (final r in [
                                'CONSUMER',
                                'INDUSTRIAL',
                                'MIL_SPEC',
                                'RESTRICTED',
                                'CLASSIFIED',
                                'COVERT',
                              ])
                                ChoiceChip(
                                  label: Text(_rarityLabel(r)),
                                  selected: _rarity == r,
                                  onSelected: (_) {
                                    setState(() {
                                      _rarity = r;
                                      _clear();
                                    });
                                  },
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                              _selected.isEmpty
                                ? 'Select skins'
                                : 'Selected: ${_selected.length}/${_maxSelectable()}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (_selected.isNotEmpty)
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
                          if (_selected.isNotEmpty &&
                              _selected.first.skin.rarity == 'COVERT')
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
                          if (_tradeIssue != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                _tradeIssue!,
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
                        itemBuilder: (_, i) => _slot(i, data),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
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
                                _selected.isNotEmpty &&
                                        _selected.first.skin.rarity == 'COVERT'
                                    ? 'TRADE РІвЂ вЂ™ SPECIAL ITEM'
                                    : 'TRADE',
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton(
                            onPressed: _selected.isNotEmpty ? _clear : null,
                            child: const Text('CLEAR'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(child: _resultCard()),
                  if (_chances.isNotEmpty)
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
                  if (_chances.isNotEmpty)
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      sliver: SliverGrid(
                        delegate: SliverChildBuilderDelegate(
                          (_, i) => _chanceCard(_chances[i]),
                          childCount: _chances.length,
                        ),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount:
                              ResponsiveGridHelper.tradeGridCrossAxisCount(
                                c.maxWidth,
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
                        (_, i) => _skinTile(filtered[i], data),
                        childCount: filtered.length,
                      ),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount:
                            ResponsiveGridHelper.tradeGridCrossAxisCount(
                              c.maxWidth,
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
