import { Field, InputType, registerEnumType } from "@nestjs/graphql"
import { IsNotEmpty, IsUUID, ValidateIf } from "class-validator"
import { DocumentScope } from "src/models/entities/document.folder"
import { IsExistUserDbValidate } from "@decorators/validation/db/user/is-exist.user.db.validate";
import { IsDefinedValidate } from "@decorators/validation/utils/is-defined.validate";

export enum OrderBy {
    ASC = 'ASC',
    DESC = 'DESC'
}
registerEnumType(OrderBy, { name: 'OrderBy' })

export enum DocumentSortableField {
    name = 'name',
    type = 'type',
    mimetype = 'mimetype',
    size = 'size',
    modifiedAt = 'modifiedAt'
}
registerEnumType(DocumentSortableField, { name: 'DocumentSortableField' })

@InputType()
export class DocumentFolderArgs {
    @Field({ nullable: false })
    // @IsNotEmpty()
    name: string

    @Field({ nullable: true })
    parentId: string

    @Field({ nullable: true })
    note: string

    @Field(_type => DocumentScope, { nullable: false, defaultValue: DocumentScope.Public })
    scope: DocumentScope

    @Field(_type => [String], { nullable: true })
    @ValidateIf(o => !o.userIds || !o.userIds.length)
    @IsDefinedValidate({
        message: 'DocumentFolderNeedDepartmentOrUser'
    })
    departmentIds: string[]

    @Field(_type => [String], { nullable: true, defaultValue: [] })
    @IsExistUserDbValidate()
    userIds: string[]
}

@InputType()
export class EditDocumentFolderArgs extends DocumentFolderArgs {
    @Field({ nullable: false })
    // @IsNotEmpty()
    // @IsUUID()
    id: string

    @Field(_type => DocumentScope, { nullable: true })
    scope: DocumentScope
}

@InputType()
export class DocumentElementFilter {
    @Field({ nullable: true, defaultValue: 0 })
    page?: number

    @Field({ nullable: true, defaultValue: 20 })
    size?: number

    @Field({ nullable: true })
    keyword?: string
}

@InputType()
export class ViewDocumentArgs {
    @Field({ nullable: false })
    token: string
}

@InputType()
export class DocumentOrderBy {
    @Field(_type => DocumentSortableField, { nullable: false })
    field: DocumentSortableField

    @Field(_type => OrderBy, { nullable: false, defaultValue: OrderBy.ASC })
    order: OrderBy
}