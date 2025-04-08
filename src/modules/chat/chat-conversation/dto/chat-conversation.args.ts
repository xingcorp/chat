import { Field, InputType, Int, registerEnumType } from "@nestjs/graphql";
import { ChatConversationGroupType, ChatConversationType } from "@models/entities/chat/conversation.chat";

registerEnumType(ChatConversationGroupType, { name: 'ChatConversationGroupType' })

@InputType()
export class ChatConversationListFilter {
    @Field(() => Int, { nullable: true, defaultValue: 25 })
    size: number

    @Field(() => Int, { nullable: true, defaultValue: 0 })
    page: number

    @Field({ nullable: true })
    keyword?: string

    @Field(_type => ChatConversationType, { nullable: true })
    type: ChatConversationType
}

@InputType()
export class ChatGroupAddInput {
    @Field(() => String, { nullable: false })
    name: string

    @Field(() => String, { nullable: true })
    imgUrl?: string

    @Field(() => String, { nullable: true })
    description?: string

    @Field(() => ChatConversationGroupType, { nullable: true })
    groupType?: ChatConversationGroupType

    @Field(() => [String], { nullable: false })
    memberIds: string[]
}

@InputType()
export class ChatGroupLeaveArgs {
    @Field(_type => String, { nullable: false })
    conversationId: string
}

@InputType()
export class ChatGroupEditInput {
    @Field(_type => String, { nullable: false })
    conversationId: string

    @Field(() => String, { nullable: true })
    name: string

    @Field(() => String, { nullable: true })
    imgUrl: string

    @Field(() => String, { nullable: true })
    description: string

    @Field(() => ChatConversationGroupType, { nullable: true })
    groupType: ChatConversationGroupType

    @Field(() => [String], { nullable: true, defaultValue: null })
    memberIds: string[]

    @Field(() => [String], { nullable: true, defaultValue: null })
    adminIds: string[]
}
