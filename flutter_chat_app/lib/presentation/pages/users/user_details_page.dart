import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_chat_app/l10n/l10n.dart';
import 'package:flutter_chat_app/presentation/blocs/user/user_bloc.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/feedback/app_progress_indicator.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/typography/app_text.dart';
import 'package:get_it/get_it.dart';

class UserDetailsPage extends StatelessWidget {
  final String userId;
  final String? displayName;

  const UserDetailsPage({
    super.key,
    required this.userId,
    this.displayName,
  });

  @override
  Widget build(BuildContext context) {
    final title = (displayName?.trim().isNotEmpty ?? false)
        ? displayName!.trim()
        : userId;

    return BlocProvider<UserBloc>(
      create: (_) => GetIt.I<UserBloc>(),
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

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                AppText(
                  loadedUser?.fullName ?? title,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                AppText(
                  'ID: $userId',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                if (loadedUser != null) ...[
                  const SizedBox(height: 12),
                  AppText(
                    loadedUser.email,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
                const SizedBox(height: 16),
                if (errorMessage != null) ...[
                  AppText(
                    errorMessage,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                ],
                if (isLoading) ...[
                  const Center(child: AppProgressIndicator.circular()),
                ] else ...[
                  Align(
                    alignment: Alignment.center,
                    child: OutlinedButton(
                      onPressed: () {
                        context.read<UserBloc>().add(LoadUserProfile(userId: userId));
                      },
                      child: const AppText('Tải thêm'),
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}
