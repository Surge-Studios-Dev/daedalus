import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// One portfolio app to promote.
class CrossPromoItem {
  const CrossPromoItem({
    required this.slug,
    required this.name,
    required this.blurb,
    required this.storeUrl,
  });
  final String slug;
  final String name;
  final String blurb;
  final String storeUrl;
}

/// House-ads slot. Every Surge app carries this so the portfolio becomes its own
/// acquisition channel: app N+1 is advertised free by the apps already shipped.
/// Feed [items] from Remote Config (a portfolio-wide JSON), filtered to exclude
/// this app's own slug. Wire onTap to Telemetry.crossPromoTap.
class CrossPromoCard extends StatelessWidget {
  const CrossPromoCard({super.key, required this.item, this.onTap});
  final CrossPromoItem item;
  final ValueChanged<CrossPromoItem>? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(item.name),
      subtitle: Text(item.blurb),
      trailing: const Icon(Icons.open_in_new),
      onTap: () {
        onTap?.call(item);
        launchUrl(Uri.parse(item.storeUrl),
            mode: LaunchMode.externalApplication);
      },
    );
  }
}
