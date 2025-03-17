import { Field, ObjectType } from "@nestjs/graphql";

@ObjectType()
export class OfficeObjectStoreGenLinkUpload {
    @Field(() => String)
    uploadUrl: string

    @Field(() => String)
    path: string
}