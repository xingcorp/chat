import { Field, Float, Int, ObjectType, registerEnumType } from "@nestjs/graphql";
import { ChatConversationGroupType, ChatConversationType, OfficeChatConversation } from "@models/entities/chat/conversation.chat";

registerEnumType(ChatConversationType, {name: 'ChatConversationType'})
registerEnumType(ChatConversationGroupType, {name: 'ChatConversationGroupType'})

@ObjectType()
export class ChatConversationListResponse {
    @Field(_type => Float, { nullable: true })
    total: number

    @Field(_type => [OfficeChatConversation], { nullable: true })
    conversations: OfficeChatConversation[]
}

@ObjectType()
export class ChatGroupResponse {
    @Field(_type => String, { nullable: false })
    conversationId: string

    @Field(() => String, { nullable: false })
    name: string

    @Field(() => String, { nullable: true })
    imgUrl?: string

    @Field(() => String, { nullable: true })
    description?: string

    @Field(() => ChatConversationGroupType, { nullable: true })
    groupType?: ChatConversationGroupType

    @Field(() => [String], { nullable: false })
    memberIds?: string[]
}
