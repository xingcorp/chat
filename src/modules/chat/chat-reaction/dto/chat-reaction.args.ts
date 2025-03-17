import { Field, InputType } from "@nestjs/graphql";

@InputType()
export class ChatReactionMessageInput {
    @Field(_type => String, { nullable: false })
    messageId: string

    @Field(_type => String, { nullable: false })
    stickerPath: string
}