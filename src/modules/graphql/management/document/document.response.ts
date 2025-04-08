import { Field, Float, Int, ObjectType } from "@nestjs/graphql"
import { PagingData } from "src/models/base/paging.response"
import { DocumentFolder } from "src/models/entities"
import { UserDocumentPermissionResponse } from "@args/document/response.document";

@ObjectType({ implements: PagingData })
export class DocumentFolderResponse implements PagingData {
    total: number
    count: number
    
    @Field(_type => [DocumentFolder], { nullable: true })
    folders?: DocumentFolder[]
}

@ObjectType({ implements: PagingData })
export class DocumentElementResponse implements PagingData {
    total: number
    count: number
    
    @Field(_type => [FolderElement], { nullable: true })
    elements?: FolderElement[]

    @Field(_type => UserDocumentPermissionResponse, { nullable: true })
    userPermissions?: UserDocumentPermissionResponse
}

@ObjectType()
export class FolderElement {
    @Field(() => String)
    id: string

    @Field({ nullable: true, defaultValue: null })
    name: string

    @Field({ nullable: true, defaultValue: null })
    type: string

    @Field({ nullable: true, defaultValue: null })
    mimetype: string

    @Field(() => Float, { nullable: true, defaultValue: null })
    size: string

    @Field(() => Float, { nullable: true})
    modifiedAt: Date

    @Field({ nullable: true, defaultValue: null })
    path: string

    @Field({ nullable: true, defaultValue: null })
    version: string

    @Field({ nullable: true, defaultValue: null })
    status: string

    @Field({ nullable: true, defaultValue: null })
    approvalVersion: string
}

@ObjectType()
export class ObjectGenLinkWriteResponse {
    @Field(() => String)
    uploadUrl: string

    @Field(() => String)
    path: string
}
