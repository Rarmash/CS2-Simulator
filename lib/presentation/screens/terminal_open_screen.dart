import 'package:flutter/material.dart';

import '../../core/utils/date_format_helper.dart';
import '../../data/models/case_dto.dart';
import '../../data/models/skin_dto.dart';
import '../../data/repositories/local_data_repository.dart';
import '../../domain/case_simulator_service.dart';
import '../../domain/dropped_skin.dart';
import '../../domain/terminal_offer.dart';
import '../helpers/source_color_helper.dart';
import '../widgets/chip_badge.dart';
import '../widgets/collectible_contents_title.dart';
import '../widgets/collectible_grid_sliver.dart';
import '../widgets/collectible_open_body.dart';
import '../widgets/collectible_open_header.dart';
import '../widgets/opening_loading_card.dart';
import '../widgets/skin_drop_card.dart';
import '../widgets/skin_grid_tile.dart';
import '../widgets/terminal_offer_card.dart';

class TerminalOpenScreen extends StatefulWidget {
  final CaseDto caseDto;
  final LocalDataRepository repository;

  const TerminalOpenScreen({
    super.key,
    required this.caseDto,
    required this.repository,
  });

  @override
  State<TerminalOpenScreen> createState() => _TerminalOpenScreenState();
}

class _TerminalOpenScreenState extends State<TerminalOpenScreen> {
  late Future<List<SkinDto>> _skinsFuture;
  final CaseSimulatorService _simulator = CaseSimulatorService();

  List<TerminalOffer> _terminalOffers = const [];
  int _terminalOfferIndex = 0;
  TerminalOffer? _acceptedTerminalOffer;
  bool _terminalStarted = false;
  bool _isTerminalLoading = false;
  DroppedSkin? _dropped;

  bool get _hasActiveTerminalOffer =>
      _terminalStarted &&
      !_isTerminalLoading &&
      _acceptedTerminalOffer == null &&
      _terminalOfferIndex < _terminalOffers.length;

  TerminalOffer? get _currentTerminalOffer {
    if (!_hasActiveTerminalOffer) {
      return null;
    }
    return _terminalOffers[_terminalOfferIndex];
  }

  bool get _isTerminalFinishedWithoutAccept =>
      _terminalStarted &&
      !_isTerminalLoading &&
      _acceptedTerminalOffer == null &&
      _terminalOfferIndex >= _terminalOffers.length;

  @override
  void initState() {
    super.initState();
    _skinsFuture = widget.repository.loadSkinsForCase(widget.caseDto.id);
  }

  Future<void> _startTerminal(List<SkinDto> skins) async {
    final offers = _simulator.buildTerminalOffers(skins: skins);

    setState(() {
      _terminalOffers = offers;
      _terminalOfferIndex = 0;
      _acceptedTerminalOffer = null;
      _terminalStarted = true;
      _dropped = null;
      _isTerminalLoading = true;
    });

    await Future.delayed(const Duration(milliseconds: 1400));

    if (!mounted) {
      return;
    }

    setState(() {
      _isTerminalLoading = false;
    });
  }

  Future<void> _acceptTerminalOffer() async {
    if (_isTerminalLoading) {
      return;
    }

    final offer = _currentTerminalOffer;
    if (offer == null) {
      return;
    }

    setState(() {
      _acceptedTerminalOffer = offer;
      _dropped = DroppedSkin(
        skin: offer.skin,
        isStatTrak: offer.isStatTrak,
        isSouvenir: false,
        skinFloat: offer.skinFloat,
        exterior: offer.exterior,
      );
    });
  }

  Future<void> _skipTerminalOffer() async {
    if (!_hasActiveTerminalOffer) {
      return;
    }

    setState(() {
      _isTerminalLoading = true;
    });

    await Future.delayed(const Duration(milliseconds: 1100));

    if (!mounted) {
      return;
    }

    setState(() {
      _terminalOfferIndex += 1;
      _isTerminalLoading = false;
    });
  }

  String _openButtonLabel() {
    if (_isTerminalLoading) {
      return 'LOADING...';
    }
    return _terminalStarted ? 'RESTART TERMINAL' : 'OPEN TERMINAL';
  }

  @override
  Widget build(BuildContext context) {
    final formattedReleaseDate = DateFormatHelper.formatReleaseDate(
      widget.caseDto.releaseDate,
    );
    final typeColor = SourceColorHelper.containerTypeColor(widget.caseDto.type);

    return Scaffold(
      appBar: AppBar(title: Text(widget.caseDto.name)),
      body: CollectibleOpenBody<SkinDto>(
        future: _skinsFuture,
        sliverBuilder: (context, constraints, skins, gridCount, aspectRatio) {
          return [
            SliverToBoxAdapter(
              child: CollectibleOpenHeader(
                assetPath: widget.caseDto.caseImage,
                imageHeight: constraints.maxWidth < 700 ? 90 : 120,
                badges: [
                  ChipBadge(label: widget.caseDto.typeLabel, color: typeColor),
                ],
                releaseDateText: formattedReleaseDate,
                description:
                    'Terminal opening is offer-based: open for free, then hold to take or skip up to five offers.',
                buttonLabel: _openButtonLabel(),
                onPressed: (_isTerminalLoading || skins.isEmpty)
                    ? null
                    : () => _startTerminal(skins),
              ),
            ),
            if (_isTerminalLoading)
              const SliverToBoxAdapter(
                child: OpeningLoadingCard(title: 'Loading terminal offer...'),
              ),
            if (_hasActiveTerminalOffer)
              SliverToBoxAdapter(
                child: TerminalOfferCard(
                  offer: _currentTerminalOffer!,
                  totalOffers: _terminalOffers.length,
                  onSkip: _skipTerminalOffer,
                  onAccept: _acceptTerminalOffer,
                ),
              ),
            if (_isTerminalFinishedWithoutAccept)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        'No offers were accepted. This terminal session is finished.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              ),
            if (_dropped != null)
              SliverToBoxAdapter(child: SkinDropCard(drop: _dropped!)),
            const SliverToBoxAdapter(
              child: CollectibleContentsTitle(title: 'Terminal contents'),
            ),
            CollectibleGridSliver<SkinDto>(
              items: skins,
              crossAxisCount: gridCount,
              childAspectRatio: aspectRatio,
              itemBuilder: (skin) {
                final isDropped = _dropped?.skin.id == skin.id;

                return SkinGridTile(
                  skin: skin,
                  highlighted: isDropped,
                  crossAxisCount: gridCount,
                );
              },
            ),
          ];
        },
      ),
    );
  }
}
