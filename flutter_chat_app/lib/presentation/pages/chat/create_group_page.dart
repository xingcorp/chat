import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_chat_app/core/di/injection.dart';
import 'package:flutter_chat_app/domain/entities/chat.dart';
import 'package:flutter_chat_app/l10n/l10n.dart';
import 'package:flutter_chat_app/presentation/blocs/chat/chat_bloc.dart';

/// **Create Group Page**
///
/// Allows users to create a new group conversation by:
/// 1. Entering group name
/// 2. Selecting members from contacts
/// 3. Optionally adding group avatar
///
/// **Architecture:** Presentation Layer
/// **Pattern:** BLoC for state management
/// **Navigation:** Returns to chat list on success
class CreateGroupPage extends StatefulWidget {
  /// Constructor
  const CreateGroupPage({super.key});

  @override
  State<CreateGroupPage> createState() => _CreateGroupPageState();
}

class _CreateGroupPageState extends State<CreateGroupPage> {
  final TextEditingController _groupNameController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final List<String> _selectedUserIds = [];
  String _searchQuery = '';

  // TODO: Replace with real user data from backend
  // For now, using mock data until user management is implemented
  final List<Map<String, dynamic>> _mockContacts = [
    {
      'id': 'user-1',
      'name': 'Nguyễn Văn A',
      'avatar': null,
      'isOnline': true,
    },
    {
      'id': 'user-2',
      'name': 'Trần Thị B',
      'avatar': null,
      'isOnline': false,
    },
    {
      'id': 'user-3',
      'name': 'Lê Văn C',
      'avatar': null,
      'isOnline': true,
    },
    {
      'id': 'user-4',
      'name': 'Phạm Thị D',
      'avatar': null,
      'isOnline': false,
    },
    {
      'id': 'user-5',
      'name': 'Hoàng Văn E',
      'avatar': null,
      'isOnline': true,
    },
  ];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _groupNameController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
    });
  }

  void _toggleUser(String userId) {
    setState(() {
      if (_selectedUserIds.contains(userId)) {
        _selectedUserIds.remove(userId);
      } else {
        _selectedUserIds.add(userId);
      }
    });
  }

  void _createGroup(BuildContext context) {
    final groupName = _groupNameController.text.trim();

    // Validation
    if (groupName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.pleaseEnterGroupName),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_selectedUserIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.pleaseSelectMembers),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Trigger create group event
    context.read<ChatBloc>().add(
          ChatEvent.createChat(
            type: ChatType.group,
            name: groupName,
            participantIds: _selectedUserIds,
          ),
        );
  }

  List<Map<String, dynamic>> get _filteredContacts {
    if (_searchQuery.isEmpty) {
      return _mockContacts;
    }
    return _mockContacts
        .where((contact) =>
            contact['name'].toString().toLowerCase().contains(_searchQuery))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<ChatBloc>(),
      child: BlocConsumer<ChatBloc, ChatState>(
        listener: (context, state) {
          state.maybeWhen(
            loaded: (chats) {
              // Group created successfully
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(context.l10n.groupCreated),
                  backgroundColor: Colors.green,
                ),
              );
              Navigator.pop(context);
            },
            error: (message) {
              // Show error message
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(message),
                  backgroundColor: Colors.red,
                ),
              );
            },
            orElse: () {},
          );
        },
        builder: (context, state) {
          final isLoading = state.maybeWhen(
            loading: () => true,
            orElse: () => false,
          );

          return Scaffold(
            appBar: AppBar(
              title: Text(context.l10n.createNewGroup),
              actions: [
                TextButton(
                  onPressed: isLoading || _selectedUserIds.isEmpty
                      ? null
                      : () => _createGroup(context),
                  child: isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          context.l10n.create,
                          style: TextStyle(
                            color: _selectedUserIds.isEmpty
                                ? Colors.grey
                                : Theme.of(context).primaryColor,
                          ),
                        ),
                ),
              ],
            ),
            body: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      // Group avatar (placeholder for future implementation)
                      Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          CircleAvatar(
                            radius: 40,
                            backgroundColor: Theme.of(context).primaryColor,
                            child: const Icon(
                              Icons.group,
                              size: 40,
                              color: Colors.white,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.secondary,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              size: 16,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Group name field
                      TextField(
                        controller: _groupNameController,
                        enabled: !isLoading,
                        decoration: InputDecoration(
                          labelText: context.l10n.groupName,
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.group),
                        ),
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 16),

                      // Search contacts
                      TextField(
                        controller: _searchController,
                        enabled: !isLoading,
                        decoration: InputDecoration(
                          labelText: context.l10n.search,
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    _searchController.clear();
                                  },
                                )
                              : null,
                        ),
                      ),
                    ],
                  ),
                ),

                // Selected contacts horizontal list
                if (_selectedUserIds.isNotEmpty)
                  Container(
                    height: 90,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      border: Border(
                        top: BorderSide(
                          color: Theme.of(context).dividerColor,
                        ),
                        bottom: BorderSide(
                          color: Theme.of(context).dividerColor,
                        ),
                      ),
                    ),
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _selectedUserIds.length,
                      itemBuilder: (context, index) {
                        final userId = _selectedUserIds[index];
                        final contact = _mockContacts.firstWhere(
                          (c) => c['id'] == userId,
                          orElse: () => {'id': userId, 'name': 'Unknown'},
                        );

                        return Padding(
                          padding: const EdgeInsets.only(right: 16),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Stack(
                                alignment: Alignment.topRight,
                                children: [
                                  CircleAvatar(
                                    radius: 30,
                                    backgroundColor:
                                        Theme.of(context).primaryColor,
                                    child: Text(
                                      contact['name']
                                          .toString()
                                          .substring(0, 1)
                                          .toUpperCase(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () => _toggleUser(userId),
                                    child: Container(
                                      padding: const EdgeInsets.all(2),
                                      decoration: const BoxDecoration(
                                        color: Colors.red,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.close,
                                        size: 14,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              SizedBox(
                                width: 60,
                                child: Text(
                                  contact['name'].toString(),
                                  style: const TextStyle(fontSize: 12),
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),

                // All contacts list
                Expanded(
                  child: _filteredContacts.isEmpty
                      ? Center(
                          child: Text(
                            context.l10n.noSearchResults,
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        )
                      : ListView.builder(
                          itemCount: _filteredContacts.length,
                          itemBuilder: (context, index) {
                            final contact = _filteredContacts[index];
                            final userId = contact['id'].toString();
                            final isSelected = _selectedUserIds.contains(userId);

                            return ListTile(
                              enabled: !isLoading,
                              leading: CircleAvatar(
                                backgroundColor: Theme.of(context).primaryColor,
                                child: Text(
                                  contact['name']
                                      .toString()
                                      .substring(0, 1)
                                      .toUpperCase(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              title: Text(contact['name'].toString()),
                              subtitle: Text(
                                contact['isOnline'] == true
                                    ? context.l10n.online
                                    : context.l10n.offline,
                                style: TextStyle(
                                  color: contact['isOnline'] == true
                                      ? Colors.green
                                      : Colors.grey,
                                ),
                              ),
                              trailing: isSelected
                                  ? const Icon(
                                      Icons.check_circle,
                                      color: Colors.green,
                                    )
                                  : const Icon(
                                      Icons.check_circle_outline,
                                      color: Colors.grey,
                                    ),
                              onTap: () => _toggleUser(userId),
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
