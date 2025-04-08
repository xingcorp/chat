import { Field, InputType, registerEnumType } from "@nestjs/graphql";
import { IsNotEmpty } from "class-validator";

export enum ChatCollections {
    USER = 'users',
    MESSAGE = 'messages',
    GROUP = 'group',
}

export enum ChatMessageType {
    TEXT = 'TEXT',
    IMAGE = 'IMAGE',
    VIDEO = 'VIDEO',
    VOICE_NOTE = 'VOICE_NOTE',
    LOCATION = 'LOCATION',
}

registerEnumType(ChatCollections, { name: 'ChatCollections' })
registerEnumType(ChatMessageType, { name: 'ChatMessageType' })

@InputType()
export class FirebaseFilterMessageArgs {
    @Field({ nullable: true })
    keyword?: string

    @Field({ nullable: false })
    @IsNotEmpty()
    senderId: string

    @Field({ nullable: true })
    receiverId?: string

    @Field(_type => ChatCollections, { nullable: false, defaultValue: ChatCollections.MESSAGE })
    type: ChatCollections

    @Field(_type => ChatMessageType,{ nullable: true})
    messageType?: ChatMessageType
}