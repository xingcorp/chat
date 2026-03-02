import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_chat_app/l10n/l10n.dart';
import 'package:flutter_chat_app/presentation/blocs/user/user_bloc.dart';
import 'package:flutter_chat_app/presentation/screens/media/image_viewer_screen.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/feedback/app_progress_indicator.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/media/app_avatar.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/typography/app_text.dart';
import 'package:get_it/get_it.dart';

class UserDetailsPage extends StatelessWidget {
  final String userId;
  final String? displayName;
  final String? avatarUrl;

  const UserDetailsPage({
    super.key,
    required this.userId,
    this.displayName,
    this.avatarUrl,
  });

  void _openFullScreenAvatar(BuildContext context, String imageUrl, String? name) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ImageViewerScreen(
          imageUrl: imageUrl,
          heroTag: 'avatar-$userId',
          title: name ?? displayName,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = (displayName?.trim().isNotEmpty ?? false)
        ? displayName!.trim()
        : userId;

    return BlocProvider<UserBloc>(
      create: (_) => GetIt.I<UserBloc>()..add(LoadUserProfile(userId: userId)),
      child: Scaffold(
        appBar: AppBar(
          title: AppText(
            context.l10n.profile,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        body: BlocBuilder<UserBloc, UserState>(
          builder: (context, state) {
            final isLoading = state is UserLoading;
            final loadedUser = state is UserProfileLoaded ? state.user : null;
            final errorMessage = state is UserError ? state.message : null;

            final resolvedAvatarUrl = loadedUser?.avatar ?? avatarUrl;
            final resolvedName = loadedUser?.fullName ?? title;

            return ListView(
              padding: const EdgeInsets.symmetric(vertical: 24),
              children: [
                _buildAvatarSection(context, resolvedAvatarUrl, resolvedName),
                const SizedBox(height: 16),

                Center(
                  child: AppText(
                    resolvedName,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ),

                if (loadedUser != null) ...[
                  const SizedBox(height: 4),
                  Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: loadedUser.isOnline ? Colors.green : Colors.grey,
                          ),
                        ),
                        const SizedBox(width: 6),
                        AppText(
                          loadedUser.isOnline
                              ? context.l10n.currentlyOnline
                              : (loadedUser.lastSeen != null
                                  ? context.l10n.lastSeenAt(_formatLastSeen(context, loadedUser.lastSeen!))
                                  : context.l10n.offline),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: loadedUser.isOnline
                                    ? Colors.green
                                    : Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 24),

                if (loadedUser != null)
                  _buildInfoCard(context, loadedUser)
                else if (isLoading)
                  const Center(child: AppProgressIndicator.circular())
                else if (errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        AppText(
                          errorMessage,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).colorScheme.error,
                              ),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: () {
                            context.read<UserBloc>().add(LoadUserProfile(userId: userId));
                          },
                          icon: const Icon(Icons.refresh, size: 18),
                          label: AppText(context.l10n.retry),
                        ),
                      ],
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildAvatarSection(BuildContext context, String? imageUrl, String name) {
    final hasImage = imageUrl != null && imageUrl.trim().isNotEmpty;

    return Center(
      child: GestureDetector(
        onTap: hasImage
            ? () => _openFullScreenAvatar(context, imageUrl, name)
            : null,
        child: Hero(
          tag: 'avatar-$userId',
          child: Stack(
            children: [
              hasImage
                  ? ClipOval(
                      child: CachedNetworkImage(
                        imageUrl: imageUrl,
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Theme.of(context).colorScheme.surfaceContainerHighest,
                          ),
                          child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                        ),
                        errorWidget: (_, __, ___) => AppAvatar.initials(
                          name: name,
                          size: AvatarSize.xlarge,
                        ),
                      ),
                    )
                  : AppAvatar.initials(
                      name: name,
                      size: AvatarSize.xlarge,
                    ),
              if (hasImage)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.fullscreen,
                      size: 16,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context, dynamic user) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Theme.of(context).dividerColor),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppText(
                context.l10n.memberInfo,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 12),
              _buildInfoRow(
                context,
                Icons.person_outline,
                context.l10n.usernameLabel,
                user.username ?? '',
              ),
              const Divider(height: 24),
              _buildInfoRow(
                context,
                Icons.email_outlined,
                context.l10n.email,
                user.email ?? '',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Theme.of(context).colorScheme.onSurfaceVariant),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppText(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 2),
              AppText(
                value.isNotEmpty ? value : '—',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatLastSeen(BuildContext context, DateTime lastSeen) {
    final now = DateTime.now();
    final diff = now.difference(lastSeen);

    if (diff.inMinutes < 1) return context.l10n.online;
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return '${lastSeen.day}/${lastSeen.month}/${lastSeen.year}';
  }
}
