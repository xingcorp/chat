enum ConversationTypeFilter {
  all,
  direct,
  group,
}

extension ConversationTypeFilterExtension on ConversationTypeFilter {
  String? get apiValue {
    switch (this) {
      case ConversationTypeFilter.all:
        return null;
      case ConversationTypeFilter.direct:
        return 'Direct';
      case ConversationTypeFilter.group:
        return 'Group';
    }
  }
}
