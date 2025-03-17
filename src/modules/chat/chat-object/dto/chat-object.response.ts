import { Field, ObjectType } from "@nestjs/graphql";

@ObjectType()
export class ChatObjectGetUrlResponse {
    @Field(_type => String, { nullable: true })
    path: string

    @Field(_type => String, { nullable: true })
    url: string
}