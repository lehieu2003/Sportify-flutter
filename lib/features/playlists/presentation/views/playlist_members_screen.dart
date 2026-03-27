import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/sportify_theme.dart';
import '../../../auth/presentation/viewmodels/auth_view_model.dart';
import '../../data/models/playlist_models.dart';
import '../../data/repositories/collaborative_playlist_repository.dart';
import '../viewmodels/playlist_members_view_model.dart';

class PlaylistMembersScreen extends StatefulWidget {
  const PlaylistMembersScreen({
    required this.playlistId,
    required this.playlistTitle,
    super.key,
  });

  final String playlistId;
  final String playlistTitle;

  @override
  State<PlaylistMembersScreen> createState() => _PlaylistMembersScreenState();
}

class _PlaylistMembersScreenState extends State<PlaylistMembersScreen> {
  late final PlaylistMembersViewModel _vm;

  @override
  void initState() {
    super.initState();
    _vm = PlaylistMembersViewModel(
      repository: context.read<CollaborativePlaylistRepository>(),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _vm.load(widget.playlistId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = context.read<AuthViewModel>().state.user?.id ?? '';
    return ChangeNotifierProvider<PlaylistMembersViewModel>.value(
      value: _vm,
      child: Consumer<PlaylistMembersViewModel>(
        builder: (context, vm, _) {
          final state = vm.state;
          PlaylistMember? currentMember;
          for (final member in state.members) {
            if (member.userId == currentUserId) {
              currentMember = member;
              break;
            }
          }
          final canManage = currentMember?.role == 'owner';
          return Scaffold(
            appBar: AppBar(
              title: Text('${widget.playlistTitle} members'),
              actions: <Widget>[
                if (canManage)
                  IconButton(
                    onPressed: state.isMutating
                        ? null
                        : () async {
                            await vm.createInviteCode(widget.playlistId);
                            final code = vm.state.latestInviteCode;
                            if (!context.mounted ||
                                code == null ||
                                code.isEmpty) {
                              return;
                            }
                            await Clipboard.setData(ClipboardData(text: code));
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Invite code copied: $code'),
                              ),
                            );
                          },
                    icon: const Icon(Icons.share_outlined),
                    tooltip: 'Create invite code',
                  ),
              ],
            ),
            body: state.isLoading
                ? const Center(child: CircularProgressIndicator())
                : Column(
                    children: <Widget>[
                      if (state.errorMessage != null)
                        Padding(
                          padding: const EdgeInsets.all(SportifySpacing.md),
                          child: Text(
                            state.errorMessage!,
                            style: const TextStyle(color: SportifyColors.error),
                          ),
                        ),
                      Expanded(
                        child: ListView.builder(
                          itemCount: state.members.length,
                          itemBuilder: (context, index) {
                            final member = state.members[index];
                            final isCurrent = member.userId == currentUserId;
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: SportifyColors.primary,
                                child: Text(
                                  member.fullName.trim().isEmpty
                                      ? '?'
                                      : member.fullName
                                            .trim()
                                            .substring(0, 1)
                                            .toUpperCase(),
                                  style: const TextStyle(
                                    color: SportifyColors.background,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              title: Text(
                                member.fullName.trim().isEmpty
                                    ? member.userId
                                    : member.fullName,
                              ),
                              subtitle: Text(
                                isCurrent
                                    ? '${member.role} • You'
                                    : member.role,
                              ),
                              trailing:
                                  canManage && !member.isOwner && !isCurrent
                                  ? PopupMenuButton<String>(
                                      onSelected: (value) async {
                                        if (value == 'remove') {
                                          await vm.removeMember(
                                            playlistId: widget.playlistId,
                                            userId: member.userId,
                                          );
                                          return;
                                        }
                                        if (value == 'transfer') {
                                          await vm.transferOwnership(
                                            playlistId: widget.playlistId,
                                            userId: member.userId,
                                          );
                                          return;
                                        }
                                        await vm.updateRole(
                                          playlistId: widget.playlistId,
                                          userId: member.userId,
                                          role: value,
                                        );
                                      },
                                      itemBuilder: (_) =>
                                          <PopupMenuEntry<String>>[
                                            const PopupMenuItem<String>(
                                              value: 'editor',
                                              child: Text('Set as editor'),
                                            ),
                                            const PopupMenuItem<String>(
                                              value: 'viewer',
                                              child: Text('Set as viewer'),
                                            ),
                                            const PopupMenuItem<String>(
                                              value: 'transfer',
                                              child: Text('Transfer ownership'),
                                            ),
                                            const PopupMenuItem<String>(
                                              value: 'remove',
                                              child: Text('Remove member'),
                                            ),
                                          ],
                                    )
                                  : null,
                            );
                          },
                        ),
                      ),
                    ],
                  ),
          );
        },
      ),
    );
  }
}
