import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../l10n/app_localizations.dart';

class CreditsPage extends StatelessWidget {
  const CreditsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final sources = <_Source>[
      _Source(
        name: l10n.creditsTanzilName,
        what: l10n.creditsTanzilWhat,
        license: l10n.creditsTanzilLicense,
        url: 'https://tanzil.net',
        notice: l10n.creditsTanzilNotice,
        licenseAsset: 'assets/data/QURAN_LICENSE.md',
      ),
      _Source(
        name: l10n.creditsAdhkarName,
        what: l10n.creditsAdhkarWhat,
        license: l10n.creditsAdhkarLicense,
        url: 'https://github.com/asellam/HisnElMuslim',
        notice: l10n.creditsAdhkarNotice,
        licenseAsset: 'assets/data/ADHKAR_LICENSE.md',
      ),
      _Source(
        name: l10n.creditsAdhanName,
        what: l10n.creditsAdhanWhat,
        license: l10n.creditsAdhanLicense,
        url: 'https://commons.wikimedia.org/wiki/File:Beautiful_adhan.ogg',
        notice: l10n.creditsAdhanNotice,
        licenseAsset: 'assets/data/ADHAN_LICENSE.md',
      ),
      _Source(
        name: l10n.creditsAudioName,
        what: l10n.creditsAudioWhat,
        license: l10n.creditsAudioLicense,
        url: 'https://everyayah.com',
        notice: l10n.creditsAudioNotice,
      ),
      _Source(
        name: l10n.creditsOpenverseName,
        what: l10n.creditsOpenverseWhat,
        license: l10n.creditsOpenverseLicense,
        url: 'https://openverse.org',
        notice: l10n.creditsOpenverseNotice,
      ),
      _Source(
        name: l10n.creditsFontsName,
        what: l10n.creditsFontsWhat,
        license: l10n.creditsFontsLicense,
        url: 'https://fonts.google.com',
        notice: l10n.creditsFontsNotice,
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: Text(l10n.creditsTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        children: [
          Text(
            l10n.creditsIntro,
            style: TextStyle(
              fontSize: 11,
              height: 1.7,
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 14),
          for (final source in sources)
            Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ExpansionTile(
                key: ValueKey('credit-${source.url}'),
                tilePadding: const EdgeInsets.symmetric(horizontal: 14),
                childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
                title: Text(
                  source.name,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurface,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      source.what,
                      style: TextStyle(
                        fontSize: 10,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      source.license,
                      style: TextStyle(
                        fontSize: 10,
                        color: scheme.onSecondaryContainer,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                children: [
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: InkWell(
                      onTap: () => _open(source.url),
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 6,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.open_in_new_rounded,
                              size: 13,
                              color: scheme.primary,
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                source.url,
                                textDirection: TextDirection.ltr,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: scheme.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: Text(
                      source.notice,
                      style: TextStyle(
                        fontSize: 10,
                        height: 1.7,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  if (source.licenseAsset != null) ...[
                    const SizedBox(height: 8),
                    _LicenseText(asset: source.licenseAsset!),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _open(String url) async {
    final uri = Uri.parse(url);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      // A device without a browser should not crash the credits page.
    }
  }
}

class _LicenseText extends StatelessWidget {
  const _LicenseText({required this.asset});

  final String asset;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    return FutureBuilder<String>(
      future: rootBundle.loadString(asset),
      builder: (context, snapshot) {
        final text = snapshot.data;
        if (text == null) return const SizedBox.shrink();
        return ExpansionTile(
          tilePadding: EdgeInsets.zero,
          dense: true,
          title: Text(
            l10n.creditsFullLicense,
            style: TextStyle(fontSize: 10, color: scheme.onSurfaceVariant),
          ),
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: SelectableText(
                text.trim(),
                textDirection: TextDirection.ltr,
                style: TextStyle(
                  fontSize: 9,
                  height: 1.6,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _Source {
  const _Source({
    required this.name,
    required this.what,
    required this.license,
    required this.url,
    required this.notice,
    this.licenseAsset,
  });

  final String name;
  final String what;
  final String license;
  final String url;
  final String notice;
  final String? licenseAsset;
}
