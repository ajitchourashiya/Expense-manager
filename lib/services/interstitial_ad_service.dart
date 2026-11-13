import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class InterstitialAdService {
  InterstitialAdService._();
  static final instance = InterstitialAdService._();
  InterstitialAd? _ad;
  bool _loading = false;
  bool _showing = false;
  int _navigationCount = 0;
  DateTime? _lastShown;
  static const testId = 'ca-app-pub-3940256099942544/1033173712';

  void preload() {
    if (_loading || _ad != null) return;
    _loading = true;
    InterstitialAd.load(
      adUnitId: testId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) { _loading = false; _ad = ad; },
        onAdFailedToLoad: (error) { _loading = false; debugPrint('Interstitial unavailable: $error'); },
      ),
    );
  }

  Future<void> showIfReady({bool force = false}) async {
    _navigationCount++;
    final now = DateTime.now();
    if (_showing || (!force && _navigationCount % 4 != 0) ||
        (_lastShown != null && now.difference(_lastShown!) < const Duration(minutes: 2))) return;
    final ad = _ad;
    if (ad == null) { preload(); return; }
    _ad = null;
    _showing = true;
    _lastShown = now;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) { ad.dispose(); _showing = false; preload(); },
      onAdFailedToShowFullScreenContent: (ad, error) { ad.dispose(); _showing = false; preload(); },
    );
    try { await ad.show(); } catch (_) { ad.dispose(); _showing = false; preload(); }
  }
}
