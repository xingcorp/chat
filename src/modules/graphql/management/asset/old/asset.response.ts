import { Field, Int, ObjectType } from "@nestjs/graphql"
import { PagingData } from "@models/base/paging.response"
import { Asset } from "@models/entities/asset/asset"

@ObjectType()
export class UpsertAssetResult {
    @Field({ nullable: true })
    assetCategory: string

    @Field({ nullable: true })
    assetCode: string

    @Field({ nullable: true })
    assetName: string

    @Field({ nullable: true })
    orgChart: string

    @Field({ nullable: true })
    serial: string

    @Field({ nullable: true })
    parameters: string

    @Field({ nullable: true })
    price: string

    @Field({ nullable: true })
    purchaseDate: string

    @Field({ nullable: true })
    warrantyDate: string

    @Field({ nullable: true })
    provider: string

    @Field({ nullable: true })
    supplyDate: string

    @Field({ nullable: true })
    officeUser: string

    @Field({ nullable: true })
    supplyReason: string

    @Field({ nullable: true })
    upgradeRepair: string

    @Field({ nullable: true })
    handOverReceipt: string

    @Field({ nullable: true })
    handOverDate: string

    @Field({ nullable: true })
    handOverReason: string

    @Field({ nullable: true })
    handOverStatus: string

    @Field({ nullable: true })
    handOverUser: string

    @Field({ nullable: true })
    result?: string
}

@ObjectType({ implements: PagingData })
export class UpsertAssetResultResponse implements PagingData {
    total: number
    count: number

    @Field(_type => String, { nullable: true })
    resultFileUrl: string
    
    @Field(_type => [UpsertAssetResult], { nullable: true })
    rows?: UpsertAssetResult[]
}

@ObjectType({ implements: PagingData })
export class AssetResponse implements PagingData {
    total: number
    count: number
    
    @Field(_type => [Asset], { nullable: true })
    assets?: Asset[]
}

@ObjectType()
export class RollingCodeObject {
    @Field(_type => String, { nullable: false })
    code: string

    @Field(() => Boolean, { nullable: true })
    lastestRollingCode: boolean
}

@ObjectType()
export class AssetNfcResponse {
    @Field(_type => RollingCodeObject, { nullable: true })
    rollingCode: RollingCodeObject

    @Field(_type => String, { nullable: true })
    tempCode: string

    // @Field(_type => UniqueCode, { nullable: false })
    // serialInfo: UniqueCode

    @Field(_type => Asset, { nullable: false })
    serialInfo: Asset
}