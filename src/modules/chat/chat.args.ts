import { ChatMessageType } from '@enum/chat/message.chat.enum';
import { ChatConversationType } from '@models/entities/chat/conversation.chat';
import { InputType, Field, Float, Int } from '@nestjs/graphql';
import { IsUUID, IsOptional } from 'class-validator';

@InputType()
export class ChatSearchArgs {
    @Field(_type => [String], { nullable: true })
    @IsUUID('4', { each: true })
    @IsOptional()
    senderIds?: string[];

    @Field(_type => [String], { nullable: true })
    @IsUUID('4', { each: true })
    @IsOptional()
    receiverIds?: string[];

    @Field(_type => [String], { nullable: true })
    @IsUUID('4', { each: true })
    @IsOptional()
    conversationIds?: string[];

    @Field(_type => [ChatConversationType], { nullable: true })
    conversationTypes?: ChatConversationType[];

    @Field(_type => [ChatMessageType], { nullable: true })
    messageTypes?: ChatMessageType[];

    @Field(_type => String, { nullable: true })
    keyword?: string;

    @Field(_type => Float, { nullable: true })
    from?: number;

    @Field(_type => Float, { nullable: true })
    to?: number;

    @Field(_type => Int, { defaultValue: 0 })
    page: number;

    @Field(_type => Int, { defaultValue: 100 })
    size: number;
}
