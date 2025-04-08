import { Field, InputType, Int, registerEnumType } from "@nestjs/graphql";
import { OrdinalCase } from "@common/enum.common";
import { WikiImportant } from "@enum/wiki/wiki.enum";

registerEnumType(OrdinalCase, {name: 'OrdinalCase'})

@InputType()
export class WikiFilter {
    @Field(() => OrdinalCase, {nullable: true})
    ordinal: OrdinalCase

    @Field(() => Int, {nullable: true})
    page: number

    @Field(() => Int, {nullable: true})
    size: number

    @Field({nullable: true})
    keyword: string

    @Field(() => [String], { nullable: true })
    folderIds: string[]

    @Field(() => [WikiImportant], { nullable: true })
    importants: WikiImportant[]

    @Field(() => [String], { nullable: true })
    tagIds: string[]
}