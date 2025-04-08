import { Field, InputType } from "@nestjs/graphql";
import { OfficeUser } from "@models/entities";
import { ValidateIf } from "class-validator";
import { IsExistAndGetUserDbValidate } from "@decorators/validation/db/user/is-exist-and-get.user.db.validate";

@InputType()
export class UserDocumentPermissionInput {
    @Field(_type => [String], { nullable: true })
    @ValidateIf(o => o.allowIds && o.allowIds.length)
    @IsExistAndGetUserDbValidate()
    allowUserIds?: string[]

    allowUsers?: OfficeUser[]

    @Field(_type => [String], { nullable: true })
    @ValidateIf(o => o.denyIds && o.denyIds.length)
    @IsExistAndGetUserDbValidate()
    denyUserIds?: string[]

    denyUsers?: OfficeUser[]
}