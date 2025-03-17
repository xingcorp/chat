import { Field, ObjectType } from "@nestjs/graphql";
import { OfficeOrgChart, OfficeUser } from "@models/entities";

@ObjectType()
export class UserDocumentPermissionItemResponse {
    @Field(_type => OfficeOrgChart, { nullable: true })
    department?: OfficeOrgChart

    @Field(_type => [OfficeUser], { nullable: true })
    users?: OfficeUser[]

}

@ObjectType()
export class UserDocumentPermissionResponse {
    @Field(_type => [UserDocumentPermissionItemResponse], { nullable: true })
    allows?: UserDocumentPermissionItemResponse[]

    @Field(_type => [UserDocumentPermissionItemResponse], { nullable: true })
    denys?: UserDocumentPermissionItemResponse[]
}