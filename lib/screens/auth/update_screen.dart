import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme.dart';

class UpdateScreen extends StatefulWidget {
  final String installedVersion;
  final String installedBuild;
  final String playStoreUrl;

  const UpdateScreen({
    super.key,
    required this.installedVersion,
    required this.installedBuild,
    required this.playStoreUrl,
  });

  @override
  State<UpdateScreen> createState() => _UpdateScreenState();
}

class _UpdateScreenState extends State<UpdateScreen> {
  bool _openingStore = false;

  // ============================================================
  // OPEN PLAY STORE
  // ============================================================

  Future<void> _openPlayStore() async {
    if (_openingStore) {
      return;
    }

    setState(() {
      _openingStore = true;
    });

    debugPrint('');
    debugPrint('==============================================');
    debugPrint('[UPDATE] OPENING PLAY STORE');
    debugPrint('==============================================');

    debugPrint('[UPDATE] URL: ${widget.playStoreUrl}');

    final uri = Uri.parse(widget.playStoreUrl);

    try {
      final opened = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      debugPrint('[UPDATE] launchUrl result: $opened');

      if (!opened) {
        throw Exception(
          'Could not open Google Play Store.',
        );
      }
    } catch (e) {
      debugPrint('[UPDATE] Failed to open Play Store: $e');

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'Could not open Google Play Store.',
            ),
          ),
        );
    } finally {
      if (mounted) {
        setState(() {
          _openingStore = false;
        });
      }
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColors.ink,
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF07111F),
                Color(0xFF0B1B2E),
                Color(0xFF102A43),
              ],
            ),
          ),
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: 430,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // ==================================================
                      // ICON
                      // ==================================================

                      Container(
                        width: 110,
                        height: 110,
                        decoration: BoxDecoration(
                          color: const Color(0xFF16C784).withValues(
                            alpha: 0.10,
                          ),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFF16C784).withValues(
                              alpha: 0.30,
                            ),
                            width: 1.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF16C784).withValues(
                                alpha: 0.14,
                              ),
                              blurRadius: 35,
                              spreadRadius: 4,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.system_update_alt_rounded,
                          color: Color(0xFF16C784),
                          size: 52,
                        ),
                      ),

                      const SizedBox(height: 30),

                      // ==================================================
                      // TITLE
                      // ==================================================

                      const Text(
                        'Update Required',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                        ),
                      ),

                      const SizedBox(height: 12),

                      Text(
                        'A newer version of Cash Flow is '
                            'available on Google Play Store.\n\n'
                            'Please update the app to continue '
                            'using the latest features, improvements '
                            'and security updates.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withValues(
                            alpha: 0.65,
                          ),
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),

                      const SizedBox(height: 28),

                      // ==================================================
                      // VERSION CARD
                      // ==================================================

                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(
                            alpha: 0.05,
                          ),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: Colors.white.withValues(
                              alpha: 0.08,
                            ),
                          ),
                        ),
                        child: Column(
                          children: [
                            _VersionRow(
                              label: 'Current version',
                              value:
                              '${widget.installedVersion} '
                                  '(${widget.installedBuild})',
                            ),

                            const SizedBox(height: 12),

                            _VersionRow(
                              label: 'Latest version',
                              value: 'Available on Play Store',
                              latest: true,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 30),

                      // ==================================================
                      // UPDATE BUTTON
                      // ==================================================

                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: _openingStore
                              ? null
                              : _openPlayStore,
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                            const Color(0xFF16C784),
                            foregroundColor: Colors.black,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius:
                              BorderRadius.circular(16),
                            ),
                          ),
                          child: _openingStore
                              ? const SizedBox(
                            width: 22,
                            height: 22,
                            child:
                            CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.black,
                            ),
                          )
                              : const Row(
                            mainAxisAlignment:
                            MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.download_rounded,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Update Now',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight:
                                  FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 18),

                      Text(
                        'Please update from Google Play Store.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withValues(
                            alpha: 0.40,
                          ),
                          fontSize: 12,
                        ),
                      ),

                      const SizedBox(height: 35),

                      Text(
                        'Developed by Riditech Solution',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withValues(
                            alpha: 0.35,
                          ),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ================================================================
// VERSION ROW
// ================================================================

class _VersionRow extends StatelessWidget {
  final String label;
  final String value;
  final bool latest;

  const _VersionRow({
    required this.label,
    required this.value,
    this.latest = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(
              alpha: 0.55,
            ),
            fontSize: 13,
          ),
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(
              color: latest
                  ? const Color(0xFF16C784)
                  : Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}
