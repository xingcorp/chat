import { Field, ObjectType } from "@nestjs/graphql"
import { PagingData } from "src/models/base/paging.response"
import { InfoBlock } from "src/models/entities"
import { InfoField, OfficeTitle } from "src/models/entities"
import { ObjectStatus } from "src/models/entities/profile.info.block"

@ObjectType({ implements: PagingData })
export class InfoBlockResponse implements PagingData {
    total: number
    count: number
    
    @Field(_type => [InfoBlock], { nullable: true })
    blocks?: InfoBlock[]
}

@ObjectType({ implements: PagingData })
export class InfoFieldResponse implements PagingData {
    total: number
    count: number
    
    @Field(_type => [InfoField], { nullable: true })
    fields?: InfoField[]
}

@ObjectType({ implements: PagingData })
export class OfficeTitleResponse implements PagingData {
    total: number
    count: number
    
    @Field(_type => [OfficeTitle], { nullable: true })
    titles?: OfficeTitle[]
}

@ObjectType({ implements: PagingData })
export class BulkUpsertBlockResponse implements PagingData {
    total: number
    count: number
    
    @Field(_type => [UpsertBlockResponse], { nullable: true })
    records?: UpsertBlockResponse[]
}

@ObjectType()
export class UpsertBlockResponse {
    @Field(_type => String, { nullable: true })
    code: string

    @Field(_type => String, { nullable: true })
    name: string

    @Field(_type => String, { nullable: true })
    status: String

    @Field(_type => String, { nullable: true })
    errorMessage: string
}

@ObjectType({ implements: PagingData })
export class BulkUpsertFieldResponse implements PagingData {
    total: number
    count: number
    
    @Field(_type => [UpsertFieldResponse], { nullable: true })
    records?: UpsertFieldResponse[]
}

@ObjectType()
export class UpsertFieldResponse {
    @Field(_type => String, { nullable: true })
    code: string

    @Field(_type => String, { nullable: true })
    name: string

    @Field(_type => String, { nullable: true })
    blockCode: string

    @Field(_type => String, { nullable: true })
    dataType: string

    @Field(_type => String, { nullable: true })
    note: string

    @Field(_type => String, { nullable: true })
    required: string

    @Field(_type => String, { nullable: true })
    optionItems: string

    @Field(_type => String, { nullable: true })
    status: string

    @Field(_type => String, { nullable: true })
    errorMessage: string
}

@ObjectType({ implements: PagingData })
export class BulkUpsertTitleResponse implements PagingData {
    total: number
    count: number
    
    @Field(_type => [UpsertTitleResponse], { nullable: true })
    records?: UpsertTitleResponse[]
}

@ObjectType()
export class UpsertTitleResponse {
    @Field(_type => String, { nullable: true })
    code: string

    @Field(_type => String, { nullable: true })
    name: string

    @Field(_type => String, { nullable: true })
    errorMessage: string
}