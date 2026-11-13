import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class BannerAdWidget extends StatefulWidget {
  const BannerAdWidget({super.key});

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  BannerAd? _bannerAd;

  bool _isLoading = true;
  bool _isLoaded = false;

  String _status = 'Loading ad...';
  String? _error;

  // TEST BANNER ID
  // Pehle isse test karo.
  static const String _adUnitId =
      // 'ca-app-pub-3940256099942544/6300978111';
      'ca-app-pub-3938693008726704/2218525604';

  @override
  void initState() {
    super.initState();

    debugPrint('================================');
    debugPrint('[ADS] BannerAdWidget CREATED');
    debugPrint('[ADS] Ad Unit ID: $_adUnitId');
    debugPrint('================================');

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAd();
    });
  }

  Future<void> _loadAd() async {
    debugPrint('[ADS] Starting banner load...');

    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _isLoaded = false;
      _status = 'Loading ad...';
      _error = null;
    });

    final width = MediaQuery.of(context).size.width.truncate();

    debugPrint('[ADS] Screen width: $width');

    final adSize =
    await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(
      width,
    );

    if (adSize == null) {
      debugPrint('[ADS] ❌ Could not calculate ad size');

      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _status = 'Ad size unavailable';
        _error = 'Could not calculate adaptive banner size.';
      });

      return;
    }

    debugPrint(
      '[ADS] Ad size: ${adSize.width} x ${adSize.height}',
    );

    final banner = BannerAd(
      adUnitId: _adUnitId,
      size: adSize,
      request: const AdRequest(),

      listener: BannerAdListener(
        onAdLoaded: (ad) {
          debugPrint('================================');
          debugPrint('[ADS] ✅ AD LOADED');
          debugPrint('[ADS] 🎉 BANNER IS VISIBLE');
          debugPrint('================================');

          if (!mounted) {
            ad.dispose();
            return;
          }

          setState(() {
            _bannerAd = ad as BannerAd;
            _isLoading = false;
            _isLoaded = true;
            _status = 'Ad loaded successfully';
            _error = null;
          });
        },

        onAdFailedToLoad: (ad, error) {
          debugPrint('================================');
          debugPrint('[ADS] ❌ AD FAILED');
          debugPrint('[ADS] Code: ${error.code}');
          debugPrint('[ADS] Message: ${error.message}');
          debugPrint('[ADS] Domain: ${error.domain}');
          debugPrint('================================');

          ad.dispose();

          if (!mounted) return;

          setState(() {
            _bannerAd = null;
            _isLoading = false;
            _isLoaded = false;
            _status = 'Ad failed to load';
            _error =
            'Code ${error.code}: ${error.message}';
          });
        },

        onAdOpened: (ad) {
          debugPrint('[ADS] Ad opened');
        },

        onAdClosed: (ad) {
          debugPrint('[ADS] Ad closed');
        },

        onAdClicked: (ad) {
          debugPrint('[ADS] Ad clicked');
        },

        onAdImpression: (ad) {
          debugPrint('[ADS] Ad impression received');
        },
      ),
    );

    debugPrint('[ADS] Calling banner.load()...');

    banner.load();
  }

  @override
  void dispose() {
    debugPrint('[ADS] BannerAdWidget disposed');

    _bannerAd?.dispose();
    _bannerAd = null;

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    debugPrint(
      '[ADS] BUILD | loading=$_isLoading loaded=$_isLoaded',
    );

    // ============================================================
    // AD LOADED
    // ============================================================

    if (_isLoaded && _bannerAd != null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: double.infinity,
            alignment: Alignment.center,
            margin: const EdgeInsets.only(
              top: 20,
              bottom: 4,
            ),
            child: SizedBox(
              width: _bannerAd!.size.width.toDouble(),
              height: _bannerAd!.size.height.toDouble(),
              child: AdWidget(
                ad: _bannerAd!,
              ),
            ),
          ),

          // const Text(
          //   '🟢 Ad visible',
          //   style: TextStyle(
          //     color: Colors.green,
          //     fontSize: 11,
          //     fontWeight: FontWeight.w600,
          //   ),
          // ),
        ],
      );
    }

    // ============================================================
    // LOADING
    // ============================================================

    if (_isLoading) {
      return Container(
        width: double.infinity,
        margin: const EdgeInsets.only(
          top: 20,
          bottom: 12,
        ),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.orange.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
              ),
            ),
            SizedBox(width: 10),
            Text(
              'Loading ad...',
              style: TextStyle(
                fontSize: 12,
                color: Colors.orange,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    // ============================================================
    // FAILED
    // ============================================================

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(
        top: 20,
        bottom: 12,
      ),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          const Text(
            '🔴 Ad failed',
            style: TextStyle(
              color: Colors.red,
              fontWeight: FontWeight.w700,
            ),
          ),

          if (_error != null) ...[
            const SizedBox(height: 4),

            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.red,
                fontSize: 11,
              ),
            ),
          ],

          const SizedBox(height: 8),

          TextButton.icon(
            onPressed: _loadAd,
            icon: const Icon(
              Icons.refresh,
              size: 18,
            ),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
