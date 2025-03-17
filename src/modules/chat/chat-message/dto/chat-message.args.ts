import { Field, Float, InputType, Int, registerEnumType } from "@nestjs/graphql";
import { ChatMessageAct, ChatMessageReactionAct, ChatMessageType } from "@enum/chat/message.chat.enum";
import { OfficeChatMessage, OfficeUser } from "@models/entities";
import { OrderBy } from "@modules/graphql/management/document/document.args";

registerEnumType(ChatMessageType, { name: 'ChatMessageType' })
registerEnumType(ChatMessageReactionAct, { name: 'ChatMessageReactionAct' })
registerEnumType(ChatMessageAct, { name: 'ChatMessageAct' })

@InputType()
export class ChatAddMessageInput {
    senderId: string

    @Field(_type => String, { nullable: true })
    receiverId: string

    @Field(_type => String, { nullable: true })
    conversationId: string

    @Field(_type => ChatMessageType, { nullable: true, defaultValue: ChatMessageType.TEXT })
    type: ChatMessageType

    @Field(_type => String, { nullable: true })
    message: string

    @Field(_type => [String], { nullable: true })
    urls: string[]

    @Field(_type => String, { nullable: true })
    replyMessageId: string

    @Field(_type => String, { nullable: true })
    forwardedFromMessageId: string

    @Field(_type => String, { nullable: true })
    fileName: string

    @Field(_type => Float, { nullable: true })
    createdAt: number
}

@InputType()
export class DeleteHistoryArgs {
    @Field(_type => String)
    conversationId: string
}

@InputType()
export class LastKeyChatMessage {
    @Field(_type => String)
    conversationId: string

    @Field(_type => Float)
    createdAt: number
}

@InputType()
export class ChatMessageUpdateReadArgs {
    @Field(_type => String)
    conversationId: string

    // @Field(_type => String)
    // lastMessageReadId: string

    @Field(_type => Int)
    readCount: number
}

@InputType()
export class ChatMessageUpdateReactionArgs {
    @Field(_type => String)
    messageId: string

    @Field(_type => String)
    code: string

    @Field(_type => ChatMessageReactionAct)
    act: ChatMessageReactionAct
}

@InputType()
export class ChatMessageUpdateArgs {
    @Field(_type => String)
    messageId: string

    @Field(_type => ChatMessageAct)
    act: ChatMessageAct

    @Field(_type => String, { nullable: true })
    message: string
}

@InputType()
export class ChatMessageGetListFilter {
    @Field(() => Int, { defaultValue: 100 })
    size: number

    @Field()
    conversationId: string

    @Field(() => LastKeyChatMessage, { nullable: true, defaultValue: null })
    lastKey?: LastKeyChatMessage

    @Field(() => ChatMessageType, { nullable: true, defaultValue: null })
    type?: ChatMessageType

    @Field(_type => OrderBy, { nullable: false, defaultValue: OrderBy.DESC })
    order?: OrderBy

    @Field(_type => Float, { nullable: true, defaultValue: null })
    from?: number
}

@InputType()
export class ChatMessageSearchFilter {
    @Field(() => Int, { nullable: true, defaultValue: 100 })
    size: number

    @Field({ nullable: true })
    keyword?: string

    @Field({ nullable: true })
    conversationId?: string

    @Field({ nullable: true })
    partnerId?: string

    @Field({ nullable: true })
    minTime?: string

    @Field({ nullable: true })
    maxTime?: string

    @Field(_type => ChatMessageType, { nullable: true })
    type?: ChatMessageType
}

export interface HandlePushMessageJobData {
    conversationId: string,
    sender: OfficeUser,
    chatMessage: OfficeChatMessage,
    accessToken: string,
    isFirstMessage: boolean,
}

export interface HandleSyncUnreadCountJobData {
    conversationId: string
    userId: string,
}

export interface HandleSyncLastMessageJobData {
    conversationId: string,
}