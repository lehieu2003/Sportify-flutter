import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/sportify_theme.dart';
import '../../../library/data/repositories/library_repository.dart';
import '../../../player/presentation/viewmodels/player_view_model.dart';
import '../../data/models/jam_models.dart';
import '../viewmodels/jam_view_model.dart';
import 'jam_session_screen.dart';

class JamSetupScreen extends StatefulWidget {
  const JamSetupScreen({super.key});

  @override
  State<JamSetupScreen> createState() => _JamSetupScreenState();
}

class _JamSetupScreenState extends State<JamSetupScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _inviteCodeController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    _inviteCodeController.dispose();
    super.dispose();
  }

  Future<void> _openSession(JamSession session) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => JamSessionScreen(sessionId: session.id),
      ),
    );
  }

  Future<void> _onCreateJam() async {
    final vm = context.read<JamViewModel>();
    final session = await vm.createSession(
      title: _titleController.text.trim().isEmpty
          ? null
          : _titleController.text.trim(),
    );
    if (!mounted || session == null) return;
    await _syncLikedSongsToJam(session.id);
    await _openSession(session);
  }

  Future<void> _syncLikedSongsToJam(String sessionId) async {
    final jamVm = context.read<JamViewModel>();
    List<String> trackIds = const <String>[];
    try {
      final libraryRepository = context.read<LibraryRepository>();
      final liked = await libraryRepository.getSavedTracks(limit: 100);
      if (!mounted) return;
      trackIds = liked
          .map((item) => item.id.trim())
          .where((id) => id.isNotEmpty)
          .toList(growable: false);
    } catch (_) {
      if (!mounted) return;
      trackIds = const <String>[];
    }
    if (trackIds.isEmpty) {
      final playerQueue = context.read<PlayerViewModel>().state.queue;
      trackIds = playerQueue
          .map((item) => item.id.trim())
          .where((id) => id.isNotEmpty)
          .toList(growable: false);
    }
    if (trackIds.isEmpty) return;
    await jamVm.syncQueueAsHost(
      sessionId: sessionId,
      trackIds: trackIds,
      queueIndex: 0,
      currentTrackId: trackIds.first,
    );
  }

  Future<void> _onJoinByCode() async {
    final code = _inviteCodeController.text.trim().toUpperCase();
    if (code.isEmpty) return;
    final vm = context.read<JamViewModel>();
    final session = await vm.joinByCode(code);
    if (!mounted || session == null) return;
    await _openSession(session);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<JamViewModel>(
      builder: (context, vm, _) {
        final state = vm.state;
        return Scaffold(
          appBar: AppBar(title: const Text('Jam')),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(SportifySpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Start a Jam',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: SportifySpacing.sm),
                TextField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Session title (optional)',
                    hintText: 'Friday Night Jam',
                  ),
                ),
                const SizedBox(height: SportifySpacing.sm),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: state.isSubmitting ? null : _onCreateJam,
                    child: state.isSubmitting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Start Jam'),
                  ),
                ),
                const SizedBox(height: SportifySpacing.xl),
                Text(
                  'Join by code',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: SportifySpacing.sm),
                TextField(
                  controller: _inviteCodeController,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(
                    labelText: 'Invite code',
                    hintText: 'AB12CD34',
                  ),
                  onSubmitted: (_) => _onJoinByCode(),
                ),
                const SizedBox(height: SportifySpacing.sm),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: state.isSubmitting ? null : _onJoinByCode,
                    child: const Text('Join Jam'),
                  ),
                ),
                if (state.errorMessage != null) ...<Widget>[
                  const SizedBox(height: SportifySpacing.md),
                  Text(
                    state.errorMessage!,
                    style: const TextStyle(color: SportifyColors.error),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
