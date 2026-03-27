import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/sportify_theme.dart';
import '../../data/repositories/collaborative_playlist_repository.dart';
import 'playlist_detail_screen.dart';

class JoinPlaylistByCodeScreen extends StatefulWidget {
  const JoinPlaylistByCodeScreen({super.key});

  @override
  State<JoinPlaylistByCodeScreen> createState() =>
      _JoinPlaylistByCodeScreenState();
}

class _JoinPlaylistByCodeScreenState extends State<JoinPlaylistByCodeScreen> {
  final TextEditingController _codeController = TextEditingController();
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _join() async {
    final code = _codeController.text.trim().toUpperCase();
    if (code.isEmpty || _isSubmitting) return;
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });
    try {
      final result = await context
          .read<CollaborativePlaylistRepository>()
          .joinByCode(code);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => PlaylistDetailScreen(
            playlistId: result.playlistId,
            initialTitle: 'Collaborative Playlist',
            isCollaborativeHint: true,
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _errorMessage = error.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Join by invite code')),
      body: Padding(
        padding: const EdgeInsets.all(SportifySpacing.md),
        child: Column(
          children: <Widget>[
            TextField(
              controller: _codeController,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                labelText: 'Invite code',
                hintText: 'AB12CD34',
              ),
              onSubmitted: (_) => _join(),
            ),
            const SizedBox(height: SportifySpacing.md),
            if (_errorMessage != null)
              Text(
                _errorMessage!,
                style: const TextStyle(color: SportifyColors.error),
              ),
            const SizedBox(height: SportifySpacing.md),
            FilledButton(
              onPressed: _isSubmitting ? null : _join,
              child: _isSubmitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Join playlist'),
            ),
          ],
        ),
      ),
    );
  }
}
