import 'package:flutter/material.dart';

import '../../data/models/skin_dto.dart';
import '../../data/repositories/local_data_repository.dart';
import '../../domain/tradeup_service.dart';

class TradeUpScreen extends StatefulWidget {
  final LocalDataRepository repository;

  const TradeUpScreen({
    super.key,
    required this.repository,
  });

  @override
  State<TradeUpScreen> createState() => _TradeUpScreenState();
}

class _TradeUpScreenState extends State<TradeUpScreen> {
  late Future<_TradeUpData> _dataFuture;

  final TradeUpService _service = TradeUpService();

  final List<SkinDto> _selected = [];
  TradeUpResult? _result;
  List<TradeUpChance> _chances = [];

  String _search = '';
  String? _rarity = 'MIL_SPEC';

  @override
  void initState() {
    super.initState();
    _dataFuture = _loadData();
  }

  Future<_TradeUpData> _loadData() async {
    final skins = await widget.repository.loadSkins();
    final cases = await widget.repository.loadCases();
    final caseToSkinIds = await widget.repository.loadCaseToSkinIds();

    final caseNameById = {
      for (final c in cases) c.id: c.name,
    };

    final skinIdToCaseNames = <String, List<String>>{};
    for (final entry in caseToSkinIds.entries) {
      final caseName = caseNameById[entry.key];
      if (caseName == null) continue;

      for (final skinId in entry.value) {
        skinIdToCaseNames.putIfAbsent(skinId, () => []).add(caseName);
      }
    }

    return _TradeUpData(
      skins: skins,
      caseToSkinIds: caseToSkinIds,
      skinIdToCaseNames: skinIdToCaseNames,
    );
  }

  Color _rarityColor(SkinDto s) {
    if (s.isSpecialItem) return Colors.amber;

    switch (s.rarity) {
      case 'MIL_SPEC':
        return Colors.blue;
      case 'RESTRICTED':
        return Colors.purple;
      case 'CLASSIFIED':
        return Colors.pink;
      case 'COVERT':
      case 'CONTRABAND':
        return Colors.red;
      case 'EXTRAORDINARY':
        return Colors.amber;
      default:
        return Colors.white24;
    }
  }

  String _rarityLabel(String rarity) {
    switch (rarity) {
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

  String _weaponTypeLabel(String type) {
    switch (type) {
      case 'PISTOL':
        return 'Pistol';
      case 'SMG':
        return 'SMG';
      case 'SNIPER_RIFLE':
        return 'Sniper Rifle';
      case 'RIFLE':
        return 'Rifle';
      case 'KNIFE':
        return 'Knife';
      case 'SHOTGUN':
        return 'Shotgun';
      case 'MACHINE_GUN':
        return 'Machine Gun';
      case 'GLOVES':
        return 'Gloves';
      case 'EQUIPMENT':
        return 'Equipment';
      default:
        return type;
    }
  }

  int _maxSelectable() {
    if (_selected.isEmpty) return 10;
    return _selected.first.rarity == 'COVERT' ? 5 : 10;
  }

  bool _canAddMore() {
    return _selected.length < _maxSelectable();
  }

  bool _tradeReady() {
    if (_selected.isEmpty) return false;
    final rarity = _selected.first.rarity;

    if (rarity == 'COVERT') {
      return _selected.length == 5;
    }
    return _selected.length == 10;
  }

  void _recalculateChances(_TradeUpData data) {
    if (_tradeReady()) {
      _chances = _service.getTradeUpChances(
        input: _selected,
        allSkins: data.skins,
        caseToSkinIds: data.caseToSkinIds,
      );
    } else {
      _chances = [];
    }
  }

  void _add(SkinDto skin, _TradeUpData data) {
    if (!_canAddMore()) return;

    if (_selected.isNotEmpty && _selected.first.rarity != skin.rarity) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All selected skins must have the same rarity')),
      );
      return;
    }

    setState(() {
      _selected.add(skin);
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
    });
  }

  Future<void> _trade(_TradeUpData data) async {
    try {
      final result = _service.tradeUp(
        input: _selected,
        allSkins: data.skins,
        caseToSkinIds: data.caseToSkinIds,
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

  int _grid(double w) {
    if (w > 1400) return 7;
    if (w > 1100) return 6;
    if (w > 800) return 5;
    if (w > 600) return 4;
    return 3;
  }

  bool _matchesSearch(SkinDto s, _TradeUpData data) {
    final q = _search.trim().toLowerCase();
    if (q.isEmpty) return true;

    final caseNames = data.skinIdToCaseNames[s.id] ?? const [];
    final caseNamesJoined = caseNames.join(' ').toLowerCase();
    final collection = (s.collection ?? '').toLowerCase();

    return s.name.toLowerCase().contains(q) ||
        s.itemDisplayName.toLowerCase().contains(q) ||
        caseNamesJoined.contains(q) ||
        collection.contains(q);
  }

  Widget _slot(int i, _TradeUpData data) {
    final skin = i < _selected.length ? _selected[i] : null;

    if (skin == null) {
      return Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white24),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Center(child: Icon(Icons.add)),
      );
    }

    final color = _rarityColor(skin);

    return GestureDetector(
      onTap: () => _removeAt(i, data),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: color, width: 2),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(4),
              child: Image.asset(
                skin.skinImage,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) =>
                const Icon(Icons.image_not_supported),
              ),
            ),
            Positioned(
              right: 2,
              top: 2,
              child: Container(
                padding: const EdgeInsets.all(2),
                color: Colors.black,
                child: const Icon(Icons.close, size: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _skinTile(SkinDto s, _TradeUpData data) {
    final color = _rarityColor(s);
    final count = _selected.where((e) => e.id == s.id).length;
    final blocked = !_canAddMore();
    final caseNames = data.skinIdToCaseNames[s.id] ?? const [];

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
                        errorBuilder: (_, __, ___) =>
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
                          style: const TextStyle(fontSize: 10, color: Colors.white70),
                        ),
                        if (caseNames.isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Text(
                            caseNames.first,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 9, color: Colors.white54),
                          ),
                        ],
                        if (s.collection != null && s.collection!.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            s.collection!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 9, color: Colors.white38),
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
                    padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text('x$count',
                        style: const TextStyle(fontSize: 10)),
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
    final color = _rarityColor(s);

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
              errorBuilder: (_, __, ___) =>
              const Icon(Icons.image_not_supported, size: 80),
            ),
            const SizedBox(height: 8),
            Text(
              '${s.isSpecialItem ? '★ ' : ''}${s.itemDisplayName} | ${s.name}',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text('Rarity: ${s.isSpecialItem ? 'Special Item' : _rarityLabel(s.rarity)}'),
            Text('Weapon type: ${_weaponTypeLabel(s.weaponType)}'),
            Text('Float: ${_result!.floatValue.toStringAsFixed(5)}'),
            Text(_result!.exterior),
          ],
        ),
      ),
    );
  }

  Widget _chanceCard(TradeUpChance chance) {
    final skin = chance.skin;
    final color = _rarityColor(skin);

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
                errorBuilder: (_, __, ___) =>
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
      appBar: AppBar(
        title: const Text('Trade-Up Simulator'),
      ),
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

            if (s.rarity != 'MIL_SPEC' &&
                s.rarity != 'RESTRICTED' &&
                s.rarity != 'CLASSIFIED' &&
                s.rarity != 'COVERT') {
              return false;
            }

            if (_rarity != null && s.rarity != _rarity) {
              return false;
            }

            return _matchesSearch(s, data);
          }).toList();

          filtered.sort((a, b) => int.parse(a.id).compareTo(int.parse(b.id)));

          return LayoutBuilder(builder: (context, c) {
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
                            hintText: 'Search by skin, case, or collection...',
                            prefixIcon: Icon(Icons.search),
                          ),
                          onChanged: (v) => setState(() => _search = v),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: [
                            for (final r in [
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
                        if (_selected.isNotEmpty && _selected.first.rarity == 'COVERT')
                          const Padding(
                            padding: EdgeInsets.only(top: 4),
                            child: Text(
                              'Covert trade-up uses exactly 5 skins',
                              style: TextStyle(color: Colors.white70, fontSize: 12),
                            ),
                          ),
                        if (!_canAddMore())
                          const Padding(
                            padding: EdgeInsets.only(top: 4),
                            child: Text(
                              'Selection is full',
                              style: TextStyle(color: Colors.amber, fontSize: 12),
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
                            onPressed: _tradeReady() ? () => _trade(data) : null,
                            child: Text(
                              _selected.isNotEmpty &&
                                  _selected.first.rarity == 'COVERT'
                                  ? 'TRADE → SPECIAL ITEM'
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
                        'Possible results',
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
                        crossAxisCount: _grid(c.maxWidth),
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
                      crossAxisCount: _grid(c.maxWidth),
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                      childAspectRatio: 0.75,
                    ),
                  ),
                ),
              ],
            );
          });
        },
      ),
    );
  }
}

class _TradeUpData {
  final List<SkinDto> skins;
  final Map<String, List<String>> caseToSkinIds;
  final Map<String, List<String>> skinIdToCaseNames;

  const _TradeUpData({
    required this.skins,
    required this.caseToSkinIds,
    required this.skinIdToCaseNames,
  });
}