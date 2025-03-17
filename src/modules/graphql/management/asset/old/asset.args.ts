import { Field, Float, InputType } from "@nestjs/graphql"

@InputType()
export class AssetFilter {
    @Field({ nullable: true, defaultValue: 0 })
    page?: number

    @Field({ nullable: true, defaultValue: 20 })
    size?: number

    @Field({ nullable: true })
    keyword?: string

    @Field({ nullable: true })
    hasNFC?: boolean
}

@InputType()
export class NfcInfoArgs {
    @Field(_type => String, { nullable: false })
    serial: string

    @Field(_type => String, { nullable: false })
    uId: string

    @Field(_type => String, { nullable: false })
    rollingCode: string
}

@InputType()
export class NfcAssignmentArgs {
    @Field(_type => Float, { nullable: true })
    latitude: number

    @Field(_type => Float, { nullable: true })
    longitude: number

    @Field(_type => [NfcInfoArgs], { nullable: true })
    nfc: NfcInfoArgs[]
}

@InputType()
export class AuditAssetArgs {
    @Field({ nullable: true })
    note: string

    @Field(() => [String], { nullable: true })
    assetIds: string[]

    @Field({ nullable: true })
    latitude: number

    @Field({ nullable: true })
    longitude: number
}

@InputType()
export class NFCInfoArgs {
    @Field(_type => String, { nullable: false })
    uId: string

    @Field(_type => String, { nullable: false })
    rollingCode: string

    @Field(_type => Float, { nullable: true })
    latitude: number

    @Field(_type => Float, { nullable: true })
    longitude: number
}

@InputType()
export class NfcHistoryArgs {
    @Field(_type => String, { nullable: true })
    id: string

    @Field(_type => String, { nullable: false })
    serial: string

    @Field(_type => String, { nullable: false })
    nfcId: string

    @Field(_type => String, { nullable: false })
    rollingCode: string

    @Field(_type => Float, { nullable: true })
    longitude: number

    @Field(_type => Float, { nullable: true })
    latitude: number

    @Field(_type => String, { nullable: true })
    address: string

    @Field(_type => String, { nullable: true })
    provinceId: string

    @Field(_type => String, { nullable: true })
    province: string

    @Field(_type => String, { nullable: true })
    districtId: string

    @Field(_type => String, { nullable: true })
    district: string

    @Field(_type => String, { nullable: true })
    wardId: string

    @Field(_type => String, { nullable: true })
    ward: string

    @Field(_type => String, { nullable: true })
    convertAddress: string

    // @Field(_type => String, { nullable: true })
    // assetCategory: string

    @Field(_type => String, { nullable: true })
    assetName: string

    @Field(_type => String, { nullable: true })
    assetCode: string
}