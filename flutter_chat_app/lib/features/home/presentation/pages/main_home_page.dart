import 'package:flutter/material.dart';
import 'package:flutter_chat_app/chat_module.dart';
import 'package:flutter_chat_app/core/base/base_widget.dart';
import 'package:flutter_chat_app/features/chat/presentation/pages/chat/chat_list_page.dart';
import 'package:flutter_chat_app/features/contacts/presentation/pages/contacts_page.dart';
import 'package:flutter_chat_app/features/settings/presentation/pages/settings_page.dart';
import 'package:flutter_chat_app/l10n/l10n.dart';

/// Main home page with bottom navigation
/// Manages tab navigation between Chats, Contacts, and Settings
class MainHomePage extends BaseStatefulWidget {
  /// Initial tab index
  final int initialIndex;

  const MainHomePage({
    super.key,
    this.initialIndex = 0,
  });

  @override
  State<MainHomePage> createState() => _MainHomePageState();
}

class _MainHomePageState extends BaseState<MainHomePage> {
  late int _currentIndex;

  // Keep pages alive using IndexedStack
  final List<Widget> _pages = const [
    ChatListPage(showBottomNavBar: false),
    ContactsPage(),
    SettingsPage(),
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  void _onTabSelected(int index) {
    if (_currentIndex != index) {
      safeSetState(() {
        _currentIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // If bottom nav bar is hidden, just show ChatListPage directly
    if (ChatModule.config?.hideBottomNavBar ?? false) {
      return const ChatListPage();
    }

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTabSelected,
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.chat),
            label: context.l10n.chats,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.contacts),
            label: context.l10n.contacts,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.settings),
            label: context.l10n.settingsTitle,
          ),
        ],
      ),
    );
  }
}
