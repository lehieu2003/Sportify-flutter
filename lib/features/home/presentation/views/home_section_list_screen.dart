import 'package:flutter/material.dart';

import '../../../../core/navigation/content_deeplink_navigator.dart';
import '../../../../core/theme/sportify_theme.dart';
import '../models/home_media_item.dart';

class HomeSectionListScreen extends StatelessWidget {
  const HomeSectionListScreen({
    super.key,
    required this.title,
    required this.items,
  });

  final String title;
  final List<HomeMediaItem> items;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ListView.builder(
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return ListTile(
            leading: const CircleAvatar(
              backgroundColor: SportifyColors.card,
              child: Icon(Icons.album_outlined),
            ),
            title: Text(item.title),
            subtitle: Text(item.subtitle),
            onTap: () {
              final albumId = item.albumId?.trim();
              if (albumId == null || albumId.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Album unavailable.')),
                );
                return;
              }
              ContentDeeplinkNavigator.open(
                context: context,
                type: 'album',
                id: albumId,
                title: item.title,
              );
            },
          );
        },
      ),
    );
  }
}
