import { Field, InputType, Int } from "@nestjs/graphql";

import {
    IsNameNotExistCategoryWikiDbValidate
} from "@decorators/validation/db/wiki/category/is-name-not-exist.category.wiki.db.validate";
import { CategoryWiki } from "@models/entities";
import { Expose, Transform } from "class-transformer";
import {
    IsExistCategoryWikiDbValidate
} from "@decorators/validation/db/wiki/category/is-exist.category.wiki.db.validate";
import { ValidateIf } from "class-validator";

@InputType()
export class WikiCategoryCreateInput {
    @Field(_type => String, {nullable: false})
    @IsNameNotExistCategoryWikiDbValidate()
    name: string
}

@InputType()
export class WikiCategoryUpdateInput extends WikiCategoryCreateInput {
    @Field(_type => String, { nullable: true })
    @IsExistCategoryWikiDbValidate()
    categoryWikiId: string

    categoryWiki?: CategoryWiki

    @Expose()
    @Transform(({obj}) => obj.categoryWikiId)
    IsNameNotExistCategoryWikiDbValidate_exceptId?: string = null
}

@InputType()
export class WikiCategoryUpsertInput extends WikiCategoryUpdateInput {
    @Field(_type => String, { nullable: true })
    @ValidateIf(o => o.categoryWikiId)
    @IsExistCategoryWikiDbValidate()
    categoryWikiId: string

    categoryWiki?: CategoryWiki

    @Expose()
    @Transform(({obj}) => obj.categoryWikiId)
    IsNameNotExistCategoryWikiDbValidate_exceptId?: string = null
}

@InputType()
export class WikiCategoryFilterInput {
    @Field(() => Int, {nullable: true})
    page: number

    @Field(() => Int, {nullable: true})
    size: number

    @Field({nullable: true})
    keyword: string
}