import { Field, Float, ObjectType, registerEnumType } from "@nestjs/graphql";
import { OfficeChatMessageReaction, OfficeUser } from "@models/entities";
import { ChatMessageType } from "@enum/chat/message.chat.enum";

registerEnumType(ChatMessageType, { name: 'ChatMessageType' })

export type OfficeChatMessageKey = {
    conversationId: string;
};

@ObjectType()
export class OfficeChatMessage {
    @Field(_type => String)
    id: string

    @Field(_type => String, { nullable: true })
    message: string

    @Field(_type => [String], { nullable: true })
    urls: string[]

    @Field(_type => ChatMessageType)
    type: ChatMessageType

    @Field(_type => Float)
    createdAt: number

    @Field(_type => Float, { nullable: true })
    deletedAt?: number

    @Field(_type => Float, { nullable: true })
    editAt?: number

    @Field({ nullable: true })
    replyMessageId: string

    @Field(_type => OfficeChatMessage, { nullable: true })
    replyMessage: OfficeChatMessage

    @Field({ nullable: true })
    forwardedFromMessageId: string

    @Field(_type => OfficeChatMessage, { nullable: true })
    forwardedFromMessage: OfficeChatMessage

    @Field({ nullable: true })
    fileName: string

    @Field()
    senderId: string

    @Field(_type => OfficeUser)
    sender: OfficeUser

    @Field()
    conversationId: string

    @Field(_type => [String], { nullable: true })
    readerIds: string[]

    @Field(_type => [OfficeChatMessageReaction], { nullable: true })
    reactions?: OfficeChatMessageReaction[]

    @Field(_type => [OfficeUser], { nullable: true })
    mentionTo: OfficeUser[]
}

// Define the schema
// export const OfficeChatMessageSchema = new dynamoose.Schema(
//     {
//         conversationId: {
//             type: String,
//             hashKey: true,
//         },
//         createdAt: {
//             type: Number,
//             rangeKey: true
//         },
//         senderId: {
//             type: String, // Reference to sender
//             required: true,
//         },
//         id: {
//             type: String, // combine conversationId_createdAt
//             required: true,
//         },
//         message: {
//             type: String,
//             required: false,
//         },
//         urls: {
//             type: Array,
//             schema: [String],
//             required: false,
//             default: [],
//         },
//         type: {
//             type: String,
//             enum: Object.keys(ChatMessageType), // Replace with actual enum values from ChatMessageType
//             required: true,
//             default: ChatMessageType.TEXT,
//         },
//         editAt: {
//             type: Date,
//             required: false,
//         },
//         replyMessageId: {
//             type: String, // Reference to replied message
//             required: false,
//         },
//         forwardedFromMessageId: {
//             type: String, // Reference to replied message
//             required: false,
//         },
//         fileName: {
//             type: String,
//             required: false,
//         },
//         reactions: {
//             type: Array,
//             schema: [String],
//             required: false,
//             default: [],
//         },
//     }
// );

// // Create the model
// const OfficeChatMessageModel = dynamoose.model<OfficeChatMessage>("chat-messages", OfficeChatMessageSchema);

// export default OfficeChatMessageModel;
