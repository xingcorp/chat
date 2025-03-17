import { Field, Float, InputType, Int } from "@nestjs/graphql";
import GraphQLJSON from "graphql-type-json";

@InputType()
export class ChatNotifyUserData {
    @Field(_type => [String], { nullable: false })
    receiverIds: string[]

    @Field(_type => String, { nullable: false })
    title: string

    @Field(_type => String, { nullable: false })
    content: string

    @Field(_type => GraphQLJSON, { nullable: true })
    metadata: JSON
}