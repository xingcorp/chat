import { Field, Float, Int, ObjectType } from "@nestjs/graphql";
import { ChatMessageType } from "@enum/chat/message.chat.enum";
import { OfficeChatMessage } from "@models/entities";
@ObjectType()
export class LastKeyChatMessageListResponse {
    @Field(_type => String, { nullable: true })
    conversationId: string

    @Field(_type => Float, { nullable: true })
    createdAt: number
}
@ObjectType()
export class ChatMessageListResponse {
    @Field(_type => LastKeyChatMessageListResponse, { nullable: true })
    lastKey: LastKeyChatMessageListResponse

    @Field(_type => [OfficeChatMessage], { nullable: true })
    messages?: OfficeChatMessage[]
}

@ObjectType()
export class ChatMessageUpdateReadResponse {
    @Field(_type => String, { nullable: true })
    conversationId: string
}