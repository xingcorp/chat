import { Field, InputType, registerEnumType } from "@nestjs/graphql";
import { CommonListFilterPaginate } from "@modules/graphql/common/common.args";
import { ChatType } from "@enum/chat/chat.enum";
import { ChatMessageType } from "@enum/chat/message.chat.enum";
import { IsDefined, ValidateIf } from "class-validator";

registerEnumType(ChatType, {name: 'ChatType'})
registerEnumType(ChatMessageType, {name: 'ChatMessageType'})

@InputType()
export class OfficeChatMessageSearchArgs extends CommonListFilterPaginate {
    @Field({ nullable: true })
    keyword?: string

    @Field(_type => ChatType, { nullable: true, defaultValue: ChatType.Conversation })
    chatType: ChatType

    @Field(_type => [ChatMessageType], { nullable: true })
    chatMessageType: ChatMessageType[]

    @Field(_type => String, { nullable: true })
    @ValidateIf(o => o.chatType && o.chatType === ChatType.Conversation)
    @IsDefined({
        message: 'ChatSearchMessageConversationRequiredPartner'
    })
    partnerId: string

    @Field(_type => String, { nullable: true })
    @ValidateIf(o => o.chatType && o.chatType === ChatType.Group)
    @IsDefined({
        message: 'ChatSearchMessageGroupRequiredInfo'
    })
    groupId: string
}

