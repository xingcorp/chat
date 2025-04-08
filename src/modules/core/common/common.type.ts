export const RedisKey = {
  UserPublicProfile: (userId: string) => `user:${userId}:profile:public`, // user status
  UserStatus: (userId: string) => `user:${userId}:status`, // user status
  UserOfflineAt: (userId: string) => `user:${userId}:offlineAt`, // user last online
  MembersInConversation: (conversationId: string) =>
    `con:${conversationId}:members`, // list member of the conversation
  ConversationUnreadCount: (conversationId: string, userId: string) =>
    `con:${conversationId}:unreadCount:mem:${userId}`,
  ConversationLastMessage: (conversationId: string) =>
    `con:${conversationId}:lastMessage`,
  ConversationsOfMember: (memberId: string) => `mem:${memberId}:conversations`, // store list conversation of the member
  ConversationName: (conversationId: string) => `con\:${conversationId}:name`, // store list conversation of the member
  Message: (messageId: string) => `messageId:${messageId}`,
  Member: (memberId: string) => `mem:${memberId}`, // member id
  MemberLastMessageRead: (conversationId: string, memberId: string) =>
    `mem:${memberId}:lastmessageread:con${conversationId}`, // member id
  MemberReactionUsed: (memberId: string) =>
    `mem:${memberId}:reaction`, // member id
  ELearningProjectLearningSkill: (projectId: string) => `project_learning_skills:${projectId}`,
  ELearningProjectLearning: (projectId: string) => `project_learning:${projectId}`,
  ELearningLearnStudent: (learnStudentId: string) => `learn_student:${learnStudentId}`,
  ELearningProjectAvatar: (projectId: string) => `avatarIds:${projectId}`,
  ELearningProjectVideo: (projectId: string) => `videoIds:${projectId}`,
  ELearningLessonAttachment: (projectId: string) => `attachmentIds:${projectId}`,
};
