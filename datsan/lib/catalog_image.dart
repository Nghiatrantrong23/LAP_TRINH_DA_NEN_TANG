import 'package:flutter/material.dart';

import 'api_client.dart';

class CatalogImage extends StatelessWidget {
  final ApiClient api;
  final String? path;
  final double size;
  const CatalogImage({super.key, required this.api, this.path, this.size = 64});
  @override
  Widget build(BuildContext context) {
    final fallback = Container(
      width: size,
      height: size,
      color: Theme.of(context).colorScheme.primaryContainer,
      child: const Icon(Icons.sports_tennis),
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: path == null
          ? fallback
          : Image.network(
              '${api.baseUrl}$path',
              width: size,
              height: size,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => fallback,
            ),
    );
  }
}

String formatMoney(num amount) {
  return '${amount.round().toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')} đ';
}
