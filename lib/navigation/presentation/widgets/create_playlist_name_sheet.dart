import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/sportify_theme.dart';
import '../../../features/playlists/data/repositories/playlist_repository.dart';

class CreatedPlaylistPayload {
  const CreatedPlaylistPayload({
    required this.id,
    required this.title,
    required this.isCollaborative,
  });

  final String id;
  final String title;
  final bool isCollaborative;
}

Future<CreatedPlaylistPayload?> showCreatePlaylistNameSheet(
  BuildContext context, {
  bool isCollaborative = false,
  String? title,
}) {
  return Navigator.of(context).push<CreatedPlaylistPayload>(
    PageRouteBuilder<CreatedPlaylistPayload>(
      opaque: false,
      barrierDismissible: true,
      barrierColor: const Color(0xAA000000),
      pageBuilder: (_, __, ___) => _CreatePlaylistNameScreen(
        isCollaborative: isCollaborative,
        title: title,
      ),
      transitionsBuilder: (_, animation, __, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.04),
              end: Offset.zero,
            ).animate(curved),
            child: child,
          ),
        );
      },
    ),
  );
}

class _CreatePlaylistNameScreen extends StatefulWidget {
  const _CreatePlaylistNameScreen({required this.isCollaborative, this.title});

  final bool isCollaborative;
  final String? title;

  @override
  State<_CreatePlaylistNameScreen> createState() =>
      _CreatePlaylistNameScreenState();
}

class _CreatePlaylistNameScreenState extends State<_CreatePlaylistNameScreen> {
  final TextEditingController _nameController = TextEditingController();
  bool _isLoadingDefaultName = true;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _prefillDefaultName());
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _prefillDefaultName() async {
    try {
      final repository = context.read<PlaylistRepository>();
      final playlists = await repository.listPlaylists(limit: 200);
      final index = playlists.length + 1;
      final defaultName = 'My playlist #$index';
      if (!mounted) return;
      _nameController.text = defaultName;
      _nameController.selection = TextSelection.collapsed(
        offset: defaultName.length,
      );
      setState(() {
        _isLoadingDefaultName = false;
      });
    } catch (_) {
      if (!mounted) return;
      _nameController.text = 'My playlist #1';
      setState(() {
        _isLoadingDefaultName = false;
      });
    }
  }

  bool get _canSubmit {
    final value = _nameController.text.trim();
    return !_isSubmitting &&
        !_isLoadingDefaultName &&
        value.isNotEmpty &&
        value.length <= 80;
  }

  Future<void> _createPlaylist() async {
    final title = _nameController.text.trim();
    if (title.isEmpty || title.length > 80 || _isSubmitting) return;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });
    try {
      final repository = context.read<PlaylistRepository>();
      final payload = await repository.createPlaylist(title: title);
      final id = (payload['id'] ?? '').toString();
      if (id.isEmpty) {
        throw Exception('Missing playlist id.');
      }
      if (!mounted) return;
      Navigator.of(context).pop(
        CreatedPlaylistPayload(
          id: id,
          title: (payload['title'] ?? title).toString(),
          isCollaborative: widget.isCollaborative,
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
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[
              Color(0xFF5B5B5B),
              Color(0xFF2A2A2A),
              Color(0xFF121212),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              children: <Widget>[
                const Spacer(flex: 2),
                Text(
                  widget.title ?? 'Give your playlist a name',
                  style: TextStyle(
                    color: SportifyColors.textPrimary,
                    fontSize: 36,
                    fontWeight: FontWeight.w700,
                    height: 1.1,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: SportifySpacing.xl),
                TextField(
                  controller: _nameController,
                  autofocus: true,
                  enabled: !_isSubmitting && !_isLoadingDefaultName,
                  textAlign: TextAlign.center,
                  maxLength: 80,
                  decoration: const InputDecoration(
                    counterText: '',
                    hintText: 'My playlist #1',
                    hintStyle: TextStyle(color: SportifyColors.textSecondary),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(
                        color: SportifyColors.textSecondary,
                      ),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: SportifyColors.textPrimary),
                    ),
                  ),
                  style: const TextStyle(
                    color: SportifyColors.textPrimary,
                    fontSize: 58,
                    fontWeight: FontWeight.w700,
                    height: 1.05,
                  ),
                  onChanged: (_) => setState(() {
                    _errorMessage = null;
                  }),
                  onSubmitted: (_) => _createPlaylist(),
                ),
                if (_errorMessage != null) ...<Widget>[
                  const SizedBox(height: SportifySpacing.sm),
                  Text(
                    _errorMessage!,
                    style: const TextStyle(color: SportifyColors.error),
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: SportifySpacing.xl),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isSubmitting
                            ? null
                            : () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          shape: const StadiumBorder(),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: SportifySpacing.md),
                    Expanded(
                      child: FilledButton(
                        onPressed: _canSubmit ? _createPlaylist : null,
                        style: FilledButton.styleFrom(
                          backgroundColor: SportifyColors.primary,
                          foregroundColor: SportifyColors.background,
                          disabledBackgroundColor: SportifyColors.card,
                          shape: const StadiumBorder(),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: _isSubmitting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Create'),
                      ),
                    ),
                  ],
                ),
                const Spacer(flex: 3),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
