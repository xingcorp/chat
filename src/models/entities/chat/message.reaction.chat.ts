import { Field, ObjectType } from "@nestjs/graphql";
import { OfficeUser } from "@models/entities";

@ObjectType()
export class OfficeChatMessageReaction {
    @Field(_type => String)
    code: string

    @Field(_type => [OfficeUser], { nullable: false })
    reactors?: OfficeUser[]

    @Field(_type => [String], { nullable: true })
    reactorIds?: string[]
}