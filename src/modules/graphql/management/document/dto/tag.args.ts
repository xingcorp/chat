import { Field, InputType, Int } from "@nestjs/graphql";

import { TagDocument } from "@models/entities";
import { Expose, Transform } from "class-transformer";
import { ValidateIf } from "class-validator";
import { IsExistTagDocumentDbValidate } from "@decorators/validation/db/document/tag/is-exist.tag.document.db.validate";
import {
    IsNameNotExistTagDocumentDbValidate
} from "@decorators/validation/db/document/tag/is-name-not-exist.tag.document.db.validate";

@InputType()
export class DocumentTagCreateInput {
    @Field(_type => String, {nullable: false})
    @IsNameNotExistTagDocumentDbValidate()
    name: string
}

@InputType()
export class DocumentTagUpdateInput extends DocumentTagCreateInput {
    @Field(_type => String, { nullable: true })
    @IsExistTagDocumentDbValidate()
    tagId: string

    tag?: TagDocument

    @Expose()
    @Transform(({obj}) => obj.tagId)
    IsNameNotExistTagDocumentDbValidate_exceptId?: string = null
}

@InputType()
export class DocumentTagUpsertInput extends DocumentTagUpdateInput {
    @Field(_type => String, { nullable: true })
    @ValidateIf(o => o.tagId)
    @IsExistTagDocumentDbValidate()
    tagId: string

    tag?: TagDocument

    @Expose()
    @Transform(({obj}) => obj.tagId)
    IsNameNotExistTagDocumentDbValidate_exceptId?: string = null
}

@InputType()
export class DocumentTagFilterInput {
    @Field(() => Int, {nullable: true})
    page: number

    @Field(() => Int, {nullable: true})
    size: number

    @Field({nullable: true})
    keyword: string
}