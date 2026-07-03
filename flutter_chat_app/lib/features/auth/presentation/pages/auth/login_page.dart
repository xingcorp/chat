import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_chat_app/core/base/base_widget.dart';
import 'package:flutter_chat_app/core/config/app_identity.dart';
import 'package:flutter_chat_app/core/constants/app_dimens.dart';
import 'package:flutter_chat_app/core/constants/app_icons.dart';
import 'package:flutter_chat_app/core/theme/app_colors.dart';
import 'package:flutter_chat_app/core/theme/app_text_styles.dart';
import 'package:flutter_chat_app/features/auth/presentation/blocs/auth/auth_bloc.dart';
import 'package:flutter_chat_app/l10n/l10n.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/buttons/app_button.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/cards/app_card.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/dividers/app_section_divider.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/inputs/input.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/layouts/app_responsive_layout.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/media/app_brand_logo.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/navigation/app_scaffold.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/typography/app_text.dart';
import 'package:go_router/go_router.dart';

/// Login page
class LoginPage extends BaseStatefulWidget {
  /// Constructor
  const LoginPage({super.key});

  @override
  BaseState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends BaseState<LoginPage> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listenWhen: (_, current) {
        if (current is! AuthError) return false;
        return current.operation == 'login' || current.operation == 'sso_login';
      },
      listener: (context, state) {
        final errorState = state as AuthError;
        final message = errorState.failure.userMessage;

        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(content: Text(message)),
          );
      },
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          final isLoading = state is AuthLoading &&
              (state.operation == 'login' || state.operation == 'sso_login');
          final isSsoLoading =
              state is AuthLoading && state.operation == 'sso_login';

          return AppResponsiveBuilder(
            builder: (context, layoutType) {
              final isDesktop = layoutType.isDesktop;

              return AppScaffold(
                dismissKeyboardOnTap: true,
                backgroundColor: _getBackgroundColor(context),
                appBar: isDesktop
                    ? null
                    : AppBar(
                        title: Text(context.l10n.login),
                      ),
                body: isDesktop
                    ? _buildDesktopBody(
                        context,
                        isLoading: isLoading,
                        isSsoLoading: isSsoLoading,
                      )
                    : _buildMobileBody(
                        context,
                        isLoading: isLoading,
                        isSsoLoading: isSsoLoading,
                      ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildMobileBody(
    BuildContext context, {
    required bool isLoading,
    required bool isSsoLoading,
  }) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 32),
          const AppBrandLogo.wordmark(
            width: 260,
            height: 72,
          ),
          const SizedBox(height: 16),
          Text(
            AppIdentity.appName,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 40),
          TextFormField(
            controller: _phoneController,
            decoration: const InputDecoration(
              labelText: 'Số điện thoại',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.phone),
            ),
            keyboardType: TextInputType.phone,
            enabled: !isLoading,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _passwordController,
            decoration: const InputDecoration(
              labelText: 'Mật khẩu',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.lock),
            ),
            obscureText: true,
            enabled: !isLoading,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: isLoading ? null : () => _submitLogin(context),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: isLoading && !isSsoLoading
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    context.l10n.login.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              const Expanded(child: Divider()),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'HOẶC',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const Expanded(child: Divider()),
            ],
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: isLoading ? null : () => _submitSsoLogin(context),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              side: const BorderSide(color: Colors.grey),
            ),
            icon: isSsoLoading
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Image.network(
                    'https://www.gstatic.com/firebasejs/ui/2.0.0/images/auth/google.svg',
                    height: 20,
                    width: 20,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.g_mobiledata,
                      size: 24,
                      color: Colors.red,
                    ),
                  ),
            label: Text(
              'Đăng nhập với Google',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: isLoading ? null : () => context.go('/forgot-password'),
            child: Text(context.l10n.forgotPassword),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(context.l10n.dontHaveAccount),
              TextButton(
                onPressed: isLoading ? null : () => context.go('/register'),
                child: Text(context.l10n.register),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopBody(
    BuildContext context, {
    required bool isLoading,
    required bool isSsoLoading,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  AppColors.backgroundDarkMode,
                  AppColors.surfaceDarkMode,
                  AppColors.backgroundDarkMode,
                ]
              : [
                  AppColors.primaryBackground.withValues(alpha: 0.55),
                  AppColors.background,
                  AppColors.secondaryBackground.withValues(alpha: 0.45),
                ],
        ),
      ),
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimens.paddingXLarge),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppDimens.breakpointLargeDesktop,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 11,
                  child: _buildDesktopHero(context),
                ),
                const SizedBox(width: AppDimens.spaceXLarge),
                ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth:
                        AppDimens.breakpointMobile - AppDimens.spaceXLarge,
                  ),
                  child: _buildDesktopFormCard(
                    context,
                    isDark: isDark,
                    isLoading: isLoading,
                    isSsoLoading: isSsoLoading,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopHero(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimens.paddingXLarge),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(AppDimens.radiusXLarge),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withValues(alpha: 0.16),
            blurRadius: AppDimens.spaceLarge,
            offset: const Offset(0, AppDimens.spaceSmall),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimens.paddingMedium,
                  vertical: AppDimens.paddingSmall,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surface.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppDimens.radiusCircular),
                  border: Border.all(
                    color: AppColors.surface.withValues(alpha: 0.18),
                  ),
                ),
                child: AppText(
                  AppIdentity.appName,
                  style: AppTextStyles.titleMedium.copyWith(
                    color: AppColors.textPrimaryDarkMode,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimens.spaceXLarge),
          const AppBrandLogo.wordmark(
            width: 280,
            height: 80,
          ),
          const SizedBox(height: AppDimens.spaceXLarge),
          AppText(
            context.l10n.welcomeToChat,
            style: AppTextStyles.heading1(
              color: AppColors.textPrimaryDarkMode,
            ),
          ),
          const SizedBox(height: AppDimens.spaceMedium),
          AppText(
            context.l10n.loginDesktopSupportingText,
            style: AppTextStyles.bodyLargeCustom(
              color: AppColors.textPrimaryDarkMode.withValues(alpha: 0.82),
            ),
          ),
          const SizedBox(height: AppDimens.spaceHuge),
          _buildDesktopFeatureCard(
            icon: Icons.apartment_rounded,
            title: context.l10n.loginDesktopWorkspaceTitle,
            description: context.l10n.loginDesktopWorkspaceDescription,
          ),
          const SizedBox(height: AppDimens.spaceMedium),
          _buildDesktopFeatureCard(
            icon: Icons.sync_rounded,
            title: context.l10n.loginDesktopSyncTitle,
            description: context.l10n.loginDesktopSyncDescription,
          ),
          const SizedBox(height: AppDimens.spaceMedium),
          _buildDesktopFeatureCard(
            icon: Icons.desktop_windows_rounded,
            title: context.l10n.loginDesktopFocusTitle,
            description: context.l10n.loginDesktopFocusDescription,
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopFeatureCard({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return AppCard.filled(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(AppDimens.paddingLarge),
      borderRadius: AppDimens.radiusLarge,
      color: AppColors.surface.withValues(alpha: 0.12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: AppDimens.spaceHuge,
            height: AppDimens.spaceHuge,
            decoration: BoxDecoration(
              color: AppColors.surface.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(AppDimens.radiusLarge),
            ),
            child: Icon(
              icon,
              color: AppColors.textPrimaryDarkMode,
            ),
          ),
          const SizedBox(width: AppDimens.spaceMedium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(
                  title,
                  style: AppTextStyles.titleMedium.copyWith(
                    color: AppColors.textPrimaryDarkMode,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppDimens.spaceXSmall),
                AppText(
                  description,
                  style: AppTextStyles.bodyMediumCustom(
                    color: AppColors.textPrimaryDarkMode.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopFormCard(
    BuildContext context, {
    required bool isDark,
    required bool isLoading,
    required bool isSsoLoading,
  }) {
    final surfaceColor = isDark ? AppColors.surfaceDarkMode : AppColors.surface;
    final secondaryTextColor =
        isDark ? AppColors.textSecondaryDarkMode : AppColors.textSecondary;

    return AppCard.elevated(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(AppDimens.paddingXLarge),
      borderRadius: AppDimens.radiusXLarge,
      color: surfaceColor,
      elevation: AppDimens.elevationLarge,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppText(
            context.l10n.login,
            style: AppTextStyles.heading4(
              color: isDark
                  ? AppColors.textPrimaryDarkMode
                  : AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppDimens.spaceSmall),
          AppText(
            context.l10n.loginDesktopFormSubtitle,
            style: AppTextStyles.bodyLargeCustom(
              color: secondaryTextColor,
            ),
          ),
          const SizedBox(height: AppDimens.spaceXLarge),
          AppTextField(
            controller: _phoneController,
            label: context.l10n.phoneNumber,
            hint: context.l10n.phoneNumber,
            prefixIcon: AppIcons.contact, // TODO: Add phone SVG icon to assets and AppIcons
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.next,
            enabled: !isLoading,
          ),
          const SizedBox(height: AppDimens.spaceMedium),
          AppPasswordField(
            controller: _passwordController,
            label: context.l10n.password,
            hint: context.l10n.password,
            textInputAction: TextInputAction.done,
            enabled: !isLoading,
            onSubmitted: (_) => _submitLogin(context),
          ),
          const SizedBox(height: AppDimens.spaceSmall),
          Align(
            alignment: Alignment.centerRight,
            child: AppButton.text(
              text: context.l10n.forgotPassword,
              onPressed:
                  isLoading ? null : () => context.go('/forgot-password'),
            ),
          ),
          const SizedBox(height: AppDimens.spaceSmall),
          AppButton.primary(
            text: context.l10n.login,
            onPressed: isLoading ? null : () => _submitLogin(context),
            isLoading: isLoading && !isSsoLoading,
            isFullWidth: true,
          ),
          AppSectionDivider(
            text: context.l10n.orLabel,
            indent: 0,
            endIndent: 0,
          ),
          AppButton.outlined(
            text: context.l10n.continueWithGoogle,
            onPressed: isLoading ? null : () => _submitSsoLogin(context),
            isLoading: isSsoLoading,
            isFullWidth: true,
            icon: Icons.open_in_new_rounded,
          ),
          const SizedBox(height: AppDimens.spaceLarge),
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: AppDimens.spaceXSmall,
            runSpacing: AppDimens.spaceXSmall,
            children: [
              AppText(
                context.l10n.dontHaveAccount,
                style: AppTextStyles.bodyMediumCustom(
                  color: secondaryTextColor,
                ),
              ),
              AppButton.text(
                text: context.l10n.register,
                onPressed: isLoading ? null : () => context.go('/register'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getBackgroundColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? AppColors.backgroundDarkMode : AppColors.background;
  }

  void _submitLogin(BuildContext context) {
    final phone = _phoneController.text.trim();
    final password = _passwordController.text;

    context.read<AuthBloc>().add(
          AuthLoginRequested(
            phone: phone,
            password: password,
          ),
        );
  }

  void _submitSsoLogin(BuildContext context) {
    context.read<AuthBloc>().add(
          const AuthSsoLoginRequested(
            provider: SsoProvider.google,
          ),
        );
  }
}
