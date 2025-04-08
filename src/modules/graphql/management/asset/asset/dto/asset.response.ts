import { Field, Float, Int, ObjectType, OmitType, PartialType } from "@nestjs/graphql";
import { PagingData } from "@models/base/paging.response";
import { Asset } from "@models/entities";
import GraphQLJSON from "graphql-type-json";
import { AssetBulkUpsertInput } from "@modules/graphql/management/asset/asset/dto/asset.args";
import { Transform } from "class-transformer";

@ObjectType({ implements: PagingData })
export class AssetListResponse implements PagingData {
    total: number
    count: number

    @Field(_type => [Asset], { nullable: true })
    records?: Asset[]
}

@ObjectType()
export class WorkProfileInfoType {
    @Field(_type => String, {nullable: true})
    key: string

    @Field(_type => String, {nullable: true})
    title: string
}

@ObjectType()
export class AssetBulkUpsertRecordResponse {
    @Field({nullable: true})
    errorMessage: string

    @Field(_type => String, {nullable: false, description: 'ten tai san'})
    name: string

    @Field(_type => String, {nullable: true, description: 'serial'})
    serial: string

    @Field(_type => String, {nullable: true, description: 'mo ta'})
    description: string

    @Field(_type => Float, {nullable: true, description: 'han bao hanh'})
    warrantyExpiredAt: number

    @Field(_type => String, {nullable: true, description: 'nha cung cap'})
    providerText: string

    @Field(_type => String, {nullable: true, description: 'khau hao'})
    monthlyDepreciation: string

    @Field(_type => String, {nullable: true})
    assetCode: string

    @Field(_type => String, {nullable: true, description: 'Ngày mua'})
    purchaseDate: string

    @Field(_type => String, {nullable: true, description: 'Hạn bảo hảnh'})
    warrantyExpiredDate: string

    @Field(_type => String, {nullable: true})
    categoryCode: string

    @Field(_type => String, {nullable: true})
    warehouseCode: string

    @Field(_type => String, {nullable: true})
    managementUserCode: string

    @Field(_type => String, {nullable: true})
    managementDepartmentCode: string

    @Field(_type => String, {nullable: true})
    assignedUserCode: string

    @Field(_type => String, {nullable: true})
    assignedDepartmentCode: string

    @Field(() => String, {nullable: true})
    warrantyByMonth: string

    @Field(() => String, {nullable: true})
    quantity: string

    @Field(() => String, {nullable: true})
    price: string
}

@ObjectType({ implements: PagingData })
export class AssetBulkUpsertResponse implements PagingData {
    total: number
    count: number

    @Field(_type => [AssetBulkUpsertRecordResponse], { nullable: true })
    records?: AssetBulkUpsertRecordResponse[]
}