// Presentation Page: Permissions Onboarding
// Enterprise-grade permissions onboarding với progressive disclosure
// Tuân thủ Material Design 3 và accessibility guidelines

// Flutter imports
import 'package:flutter/material.dart';

// Third-party package imports
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lottie/lottie.dart';

// App imports
import 'package:flutter_chat_app/core/theme/app_colors.dart';
import 'package:flutter_chat_app/core/theme/app_text_styles.dart';
import 'package:flutter_chat_app/core/utils/app_localizations.dart';
import 'package:flutter_chat_app/domain/entities/permission_entity.dart';
import 'package:flutter_chat_app/presentation/blocs/permissions/permissions_bloc.dart';
import 'package:flutter_chat_app/presentation/widgets/permissions/permission_card_widget.dart';

class PermissionsOnboardingPage extends StatefulWidget {
  const PermissionsOnboardingPage({super.key});

  @override
  State<PermissionsOnboardingPage> createState() => _PermissionsOnboardingPageState();
}

class _PermissionsOnboardingPageState extends State<PermissionsOnboardingPage>
    with TickerProviderStateMixin {
  
  late PageController _pageController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  int _currentPage = 0;
  bool _isRequestingPermissions = false;

  // Permissions flow theo priority
  final List<List<PermissionType>> _permissionSteps = [
    // Step 1: Critical permissions
    [
      PermissionType.notification,
    ],
    // Step 2: Core messaging permissions
    [
      PermissionType.camera,
      PermissionType.microphone,
      PermissionType.storage,
    ],
    // Step 3: Enhanced features
    [
      PermissionType.contacts,
      PermissionType.location,
    ],
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _animationController.forward();
    
    // Initialize permissions bloc
    context.read<PermissionsBloc>().add(const PermissionsInitializeEvent());
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: BlocConsumer<PermissionsBloc, PermissionsState>(
          listener: _handlePermissionsStateChange,
          builder: (context, state) {
            return FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                children: [
                  _buildHeader(),
                  Expanded(
                    child: PageView.builder(
                      controller: _pageController,
                      onPageChanged: _onPageChanged,
                      itemCount: _permissionSteps.length + 1, // +1 for completion page
                      itemBuilder: (context, index) {
                        if (index < _permissionSteps.length) {
                          return _buildPermissionStep(
                            context,
                            index,
                            _permissionSteps[index],
                            state,
                          );
                        } else {
                          return _buildCompletionPage(context, state);
                        }
                      },
                    ),
                  ),
                  _buildBottomNavigation(context, state),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          // Logo và branding
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.security,
              color: Colors.white,
              size: 40,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            AppLocalizations.of(context).permissionsOnboardingTitle,
            style: AppTextStyles.headlineMedium.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context).permissionsOnboardingSubtitle,
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          // Progress indicator
          _buildProgressIndicator(),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        _permissionSteps.length + 1,
        (index) => Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: index <= _currentPage
                ? AppColors.primary
                : AppColors.surfaceVariant,
          ),
        ),
      ),
    );
  }

  Widget _buildPermissionStep(
    BuildContext context,
    int stepIndex,
    List<PermissionType> permissions,
    PermissionsState state,
  ) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          // Step title
          Text(
            _getStepTitle(stepIndex),
            style: AppTextStyles.headlineSmall.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            _getStepDescription(stepIndex),
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          
          // Permissions list
          Expanded(
            child: ListView.separated(
              itemCount: permissions.length,
              separatorBuilder: (context, index) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final permission = permissions[index];
                return PermissionCardWidget(
                  permissionType: permission,
                  onTap: () => _requestSinglePermission(permission),
                  isLoading: _isRequestingPermissions,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletionPage(BuildContext context, PermissionsState state) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Success animation
          Lottie.asset(
            'assets/animations/success.json',
            width: 200,
            height: 200,
            repeat: false,
          ),
          const SizedBox(height: 32),
          Text(
            AppLocalizations.of(context).permissionsOnboardingComplete,
            style: AppTextStyles.headlineMedium.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            AppLocalizations.of(context).permissionsOnboardingCompleteDescription,
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 48),
          
          // Summary của permissions
          if (state is PermissionsLoadedState || state is PermissionsSuccessState)
            _buildPermissionsSummary(context, state),
        ],
      ),
    );
  }

  Widget _buildPermissionsSummary(BuildContext context, PermissionsState state) {
    final summary = state is PermissionsLoadedState 
        ? state.summary 
        : (state as PermissionsSuccessState).summary;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outline),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                summary.allCriticalGranted ? Icons.check_circle : Icons.warning,
                color: summary.allCriticalGranted ? AppColors.success : AppColors.warning,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  summary.allCriticalGranted
                      ? 'Tất cả quyền quan trọng đã được cấp'
                      : 'Một số quyền quan trọng chưa được cấp',
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '${summary.granted.length}/${PermissionType.values.length} quyền đã được cấp',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigation(BuildContext context, PermissionsState state) {
    return Container(
      padding: const EdgeInsets.all(24.0),
      child: Row(
        children: [
          // Back button
          if (_currentPage > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: _isRequestingPermissions ? null : _goToPreviousPage,
                child: Text(AppLocalizations.of(context).back),
              ),
            ),
          
          if (_currentPage > 0) const SizedBox(width: 16),
          
          // Next/Complete button
          Expanded(
            flex: _currentPage == 0 ? 1 : 2,
            child: ElevatedButton(
              onPressed: _isRequestingPermissions ? null : _handleNextAction,
              child: _isRequestingPermissions
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(_getNextButtonText()),
            ),
          ),
        ],
      ),
    );
  }

  void _handlePermissionsStateChange(BuildContext context, PermissionsState state) {
    if (state is PermissionsRequestingState || state is PermissionsRequestBatchingState) {
      setState(() {
        _isRequestingPermissions = true;
      });
    } else {
      setState(() {
        _isRequestingPermissions = false;
      });
    }

    if (state is PermissionsErrorState) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.message),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
    });
  }

  void _goToPreviousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _goToNextPage() {
    if (_currentPage < _permissionSteps.length) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  void _handleNextAction() {
    if (_currentPage < _permissionSteps.length) {
      // Request permissions for current step
      final permissions = _permissionSteps[_currentPage];
      context.read<PermissionsBloc>().add(
        PermissionsRequestBatchEvent(
          types: permissions,
          showRationale: true,
        ),
      );
      
      // Move to next page after a delay
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) {
          _goToNextPage();
        }
      });
    } else {
      _completeOnboarding();
    }
  }

  void _requestSinglePermission(PermissionType type) {
    context.read<PermissionsBloc>().add(
      PermissionsRequestEvent(
        type: type,
        showRationale: true,
        context: context,
      ),
    );
  }

  void _completeOnboarding() {
    Navigator.of(context).pushReplacementNamed('/home');
  }

  String _getStepTitle(int stepIndex) {
    switch (stepIndex) {
      case 0:
        return 'Thông báo quan trọng';
      case 1:
        return 'Tính năng cốt lõi';
      case 2:
        return 'Tính năng nâng cao';
      default:
        return 'Cấp quyền';
    }
  }

  String _getStepDescription(int stepIndex) {
    switch (stepIndex) {
      case 0:
        return 'Cho phép nhận thông báo để không bỏ lỡ tin nhắn quan trọng';
      case 1:
        return 'Cấp quyền cho các tính năng cơ bản của ứng dụng chat';
      case 2:
        return 'Kích hoạt các tính năng nâng cao để trải nghiệm tốt hơn';
      default:
        return 'Cấp quyền cho ứng dụng';
    }
  }

  String _getNextButtonText() {
    if (_currentPage < _permissionSteps.length) {
      return 'Cấp quyền & Tiếp tục';
    } else {
      return 'Hoàn thành';
    }
  }
}
