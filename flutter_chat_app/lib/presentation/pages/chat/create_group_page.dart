import 'package:flutter/material.dart';
import 'package:flutter_chat_app/l10n/l10n.dart';

/// Create group page
class CreateGroupPage extends StatefulWidget {
  /// Constructor
  const CreateGroupPage({Key? key}) : super(key: key);

  @override
  State<CreateGroupPage> createState() => _CreateGroupPageState();
}

class _CreateGroupPageState extends State<CreateGroupPage> {
  final TextEditingController _groupNameController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final List<Map<String, dynamic>> _selectedContacts = [];
  
  final List<Map<String, dynamic>> _mockContacts = [
    {
      'id': '1',
      'name': 'Nguyễn Văn A',
      'avatar': null,
      'isOnline': true,
    },
    {
      'id': '2',
      'name': 'Trần Thị B',
      'avatar': null,
      'isOnline': false,
    },
    {
      'id': '3',
      'name': 'Lê Văn C',
      'avatar': null,
      'isOnline': true,
    },
    {
      'id': '4',
      'name': 'Phạm Thị D',
      'avatar': null,
      'isOnline': false,
    },
    {
      'id': '5',
      'name': 'Hoàng Văn E',
      'avatar': null,
      'isOnline': true,
    },
  ];
  
  @override
  void dispose() {
    _groupNameController.dispose();
    _searchController.dispose();
    super.dispose();
  }
  
  void _toggleContact(Map<String, dynamic> contact) {
    setState(() {
      final index = _selectedContacts.indexWhere((c) => c['id'] == contact['id']);
      if (index >= 0) {
        _selectedContacts.removeAt(index);
      } else {
        _selectedContacts.add(contact);
      }
    });
  }
  
  void _createGroup() {
    if (_groupNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.pleaseEnterGroupName),
        ),
      );
      return;
    }
    
    if (_selectedContacts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.pleaseSelectMembers),
        ),
      );
      return;
    }
    
    // Create group and navigate back
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.createNewGroup),
        actions: [
          TextButton(
            onPressed: _selectedContacts.isNotEmpty ? _createGroup : null,
            child: Text(context.l10n.create),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Group avatar
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    const CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.green,
                      child: Icon(
                        Icons.group,
                        size: 40,
                        color: Colors.white,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.blue,
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
                  decoration: const InputDecoration(
                    labelText: 'Tên nhóm',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.group),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Search contacts
                TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    labelText: 'Tìm kiếm bạn bè',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.search),
                  ),
                ),
              ],
            ),
          ),
          
          // Selected contacts
          if (_selectedContacts.isNotEmpty)
            Container(
              height: 90,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                border: Border(
                  top: BorderSide(color: Colors.grey[300]!),
                  bottom: BorderSide(color: Colors.grey[300]!),
                ),
              ),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _selectedContacts.length,
                itemBuilder: (context, index) {
                  final contact = _selectedContacts[index];
                  return Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: Column(
                      children: [
                        Stack(
                          alignment: Alignment.topRight,
                          children: [
                            CircleAvatar(
                              radius: 30,
                              backgroundColor: Colors.blue,
                              child: Text(
                                contact['name'].substring(0, 1),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: () => _toggleContact(contact),
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
                        Text(
                          contact['name'],
                          style: const TextStyle(fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          
          // All contacts
          Expanded(
            child: ListView.builder(
              itemCount: _mockContacts.length,
              itemBuilder: (context, index) {
                final contact = _mockContacts[index];
                final isSelected = _selectedContacts.any((c) => c['id'] == contact['id']);
                
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.blue,
                    child: Text(
                      contact['name'].substring(0, 1),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(contact['name']),
                  subtitle: Text(
                    contact['isOnline'] ? 'Trực tuyến' : 'Ngoại tuyến',
                    style: TextStyle(
                      color: contact['isOnline'] ? Colors.green : Colors.grey,
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
                  onTap: () => _toggleContact(contact),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
} 