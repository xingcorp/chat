/// **WEB HOME SCREEN**
///
/// Web-optimized home screen for Flutter chat app
/// Provides responsive layout and web-specific features
///
/// **Features:**
/// - Responsive design for web browsers
/// - Enterprise theme and i18n integration
/// - Web-optimized navigation
/// - Performance monitoring

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_chat_app/l10n/l10n.dart';
import 'package:flutter_chat_app/presentation/blocs/locale/locale_cubit.dart';
import 'package:flutter_chat_app/presentation/blocs/theme/theme_cubit.dart';
import 'package:flutter_chat_app/presentation/widgets/settings/enterprise_settings_screen.dart';

/// **WEB HOME SCREEN**
class WebHomeScreen extends StatelessWidget {
  const WebHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.appTitle),
        centerTitle: true,
        actions: [
          // Theme Toggle
          BlocBuilder<ThemeCubit, ThemeState>(
            builder: (context, state) {
              return IconButton(
                icon: Icon(
                  state.isDarkMode ? Icons.light_mode : Icons.dark_mode,
                ),
                tooltip: 'Toggle Theme',
                onPressed: () {
                  context.read<ThemeCubit>().toggleTheme();
                },
              );
            },
          ),
          
          // Language Toggle
          BlocBuilder<LocaleCubit, LocaleState>(
            builder: (context, state) {
              return IconButton(
                icon: const Icon(Icons.language),
                tooltip: 'Change Language',
                onPressed: () {
                  context.read<LocaleCubit>().toggleLocale();
                },
              );
            },
          ),
          
          // Settings
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Settings',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const EnterpriseSettingsScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: const WebHomeBody(),
    );
  }
}

/// **WEB HOME BODY**
class WebHomeBody extends StatelessWidget {
  const WebHomeBody({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Responsive layout based on screen width
        if (constraints.maxWidth > 1200) {
          return _buildDesktopLayout(context);
        } else if (constraints.maxWidth > 800) {
          return _buildTabletLayout(context);
        } else {
          return _buildMobileLayout(context);
        }
      },
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    return Row(
      children: [
        // Sidebar
        Container(
          width: 300,
          color: Theme.of(context).colorScheme.surfaceVariant,
          child: _buildSidebar(context),
        ),
        
        // Main content
        Expanded(
          child: _buildMainContent(context),
        ),
        
        // Right panel
        Container(
          width: 250,
          color: Theme.of(context).colorScheme.surfaceVariant,
          child: _buildRightPanel(context),
        ),
      ],
    );
  }

  Widget _buildTabletLayout(BuildContext context) {
    return Row(
      children: [
        // Sidebar
        Container(
          width: 250,
          color: Theme.of(context).colorScheme.surfaceVariant,
          child: _buildSidebar(context),
        ),
        
        // Main content
        Expanded(
          child: _buildMainContent(context),
        ),
      ],
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    return _buildMainContent(context);
  }

  Widget _buildSidebar(BuildContext context) {
    return Column(
      children: [
        // User profile section
        Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: Theme.of(context).colorScheme.primary,
                child: const Icon(Icons.person, size: 30, color: Colors.white),
              ),
              const SizedBox(height: 8),
              Text(
                'Web User',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Text(
                'Online',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.green,
                ),
              ),
            ],
          ),
        ),
        
        const Divider(),
        
        // Navigation items
        Expanded(
          child: ListView(
            children: [
              ListTile(
                leading: const Icon(Icons.chat),
                title: Text(context.l10n.chats),
                onTap: () {
                  // Navigate to chats
                },
              ),
              ListTile(
                leading: const Icon(Icons.contacts),
                title: Text(context.l10n.contacts),
                onTap: () {
                  // Navigate to contacts
                },
              ),
              ListTile(
                leading: const Icon(Icons.group),
                title: Text(context.l10n.groups),
                onTap: () {
                  // Navigate to groups
                },
              ),
              ListTile(
                leading: const Icon(Icons.settings),
                title: Text(context.l10n.settingsTitle),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const EnterpriseSettingsScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMainContent(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 120,
            color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
          ),
          const SizedBox(height: 24),
          Text(
            context.l10n.welcomeToChat,
            style: Theme.of(context).textTheme.headlineMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'Web version of Flutter Chat App with enterprise features',
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          
          // Feature cards
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              _buildFeatureCard(
                context,
                Icons.palette,
                'Dynamic Themes',
                'Material Design 3 with dynamic colors',
              ),
              _buildFeatureCard(
                context,
                Icons.language,
                'Internationalization',
                'Multi-language support with RTL',
              ),
              _buildFeatureCard(
                context,
                Icons.speed,
                'Performance',
                'Optimized for web browsers',
              ),
              _buildFeatureCard(
                context,
                Icons.security,
                'Enterprise Ready',
                'Production-grade features',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRightPanel(BuildContext context) {
    return Column(
      children: [
        // Performance metrics
        Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Performance',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              BlocBuilder<ThemeCubit, ThemeState>(
                builder: (context, state) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Theme: ${state.themeMode.name}'),
                      if (state.lastSwitchDuration != null)
                        Text('Switch: ${state.lastSwitchDuration!.inMilliseconds}ms'),
                      Text('Status: ${state.isPerformanceOptimal ? '✅' : '⚠️'}'),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
        
        const Divider(),
        
        // Locale info
        Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Localization',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              BlocBuilder<LocaleCubit, LocaleState>(
                builder: (context, state) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Language: ${state.effectiveLocale.languageCode.toUpperCase()}'),
                      Text('RTL: ${state.isRtl ? 'Yes' : 'No'}'),
                      if (state.lastSwitchDuration != null)
                        Text('Switch: ${state.lastSwitchDuration!.inMilliseconds}ms'),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureCard(
    BuildContext context,
    IconData icon,
    String title,
    String description,
  ) {
    return SizedBox(
      width: 200,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(
                icon,
                size: 48,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
