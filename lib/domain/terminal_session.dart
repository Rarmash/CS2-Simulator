import 'terminal_offer.dart';

class TerminalSession {
  final List<TerminalOffer> offers;
  final int currentIndex;
  final TerminalOffer? acceptedOffer;

  const TerminalSession({
    required this.offers,
    required this.currentIndex,
    required this.acceptedOffer,
  });

  TerminalOffer? get currentOffer {
    if (currentIndex < 0 || currentIndex >= offers.length) return null;
    return offers[currentIndex];
  }

  bool get isFinished => acceptedOffer != null || currentIndex >= offers.length;
  int get offersRemaining => offers.length - currentIndex;
}