import { Field, ObjectType } from "@nestjs/graphql";

@ObjectType()
export class FieldsListResponse {
    @Field(_type => [String], { nullable: true })
    fields?: String[]
}