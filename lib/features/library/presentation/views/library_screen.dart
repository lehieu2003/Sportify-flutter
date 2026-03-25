import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/sportify_theme.dart';
import '../viewmodels/library_view_model.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<LibraryViewModel>().loadSavedTracks();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LibraryViewModel>(
      builder: (context, vm, _) {
        final state = vm.state;
        if (state.isLoading && state.items.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        return RefreshIndicator(
          onRefresh: vm.loadSavedTracks,
          child: ListView.builder(
            itemCount: state.items.length + 1,
            itemBuilder: (context, index) {
              if (index == 0 && state.errorMessage != null) {
                return Padding(
                  padding: const EdgeInsets.all(SportifySpacing.md),
                  child: Text(
                    state.errorMessage!,
                    style: const TextStyle(color: SportifyColors.error),
                  ),
                );
              }
              if (index >= state.items.length) {
                return const SizedBox(height: 64);
              }
              final item = state.items[index];
              return ListTile(
                leading: const CircleAvatar(child: Icon(Icons.queue_music)),
                title: Text(item.title),
                subtitle: Text(item.artist),
                trailing: IconButton(
                  onPressed: () => vm.unsaveTrack(item.id),
                  icon: const Icon(Icons.favorite, color: SportifyColors.primary),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
