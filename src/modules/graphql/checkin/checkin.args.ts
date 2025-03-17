import { Field, Float, InputType, Int } from "@nestjs/graphql"
import { IsArray, IsNotEmpty, IsUUID, ValidateIf } from "class-validator"
import { CheckInStatus } from "src/models/entities/checkin"
import { IsDefinedValidate } from "@decorators/validation/utils/is-defined.validate";
import { IsExistCheckInDbValidate } from "@decorators/validation/db/check-in/is-exist.check-in.db.validate";

@InputType()
export class PublicIpArgs {
    @Field({ nullable: false })
    @IsNotEmpty()
    ip: string

    @Field({ nullable: true })
    note: string
}

@InputType()
export class WhitelistIPFilter {
    @Field({ nullable: true, defaultValue: 0 })
    page?: number

    @Field({ nullable: true, defaultValue: 20 })
    size?: number

    @Field({ nullable: true })
    keyword?: string
}

@InputType()
export class CheckInPlaceFilter {
    @Field({ nullable: true, defaultValue: 0 })
    page?: number

    @Field({ nullable: true, defaultValue: 20 })
    size?: number

    @Field({ nullable: true })
    keyword?: string

    @Field({ nullable: true })
    provinceId?: string

    @Field({ nullable: true })
    districtId?: string

    @Field({ nullable: true })
    wardId?: string

    @Field({ nullable: true })
    ipValidation?: boolean

    @Field(_type => Float, { nullable: true })
    longitude?: number

    @Field(_type => Float, { nullable: true })
    latitude?: number

    @Field(_type => Float, { nullable: true, defaultValue: 300 })
    limit?: number
}

@InputType()
export class CheckInPlaceArgs {
    @Field({ nullable: false })
    @IsNotEmpty()
    name: string

    @Field({ nullable: false })
    @IsNotEmpty()
    @IsUUID()
    addressZoneId: string

    @Field({ nullable: false })
    @IsNotEmpty()
    address: string

    @Field({ nullable: false })
    latitude: number

    @Field({ nullable: false })
    longitude: number

    @Field({ nullable: true })
    note: string

    @Field(() => Boolean, { nullable: false, defaultValue: false })
    ipValidation: boolean
}

@InputType()
export class UserCheckInArgs {
    @Field(_type => String, { nullable: true })
    @ValidateIf(o => !o.secret)
    @IsDefinedValidate({
        message: 'CheckInNeedPlaceNotFound'
    })
    placeId: string

    @Field(_type => String, { nullable: true })
    @ValidateIf(o => o.secret)
    @IsExistCheckInDbValidate()
    secret: string

    @Field(_type => [String], { nullable: true })
    imageIds: string[]

    @Field({ nullable: true })
    description: string

    @Field({ nullable: true })
    latitude: number

    @Field({ nullable: true })
    longitude: number
}

@InputType()
export class EditCheckInPlaceArgs {
    @Field({ nullable: false })
    @IsNotEmpty()
    @IsUUID()
    id: string

    @Field({ nullable: true })
    name: string

    @Field({ nullable: true })
    addressZoneId: string

    @Field({ nullable: true })
    address: string

    @Field({ nullable: true })
    latitude: number

    @Field({ nullable: true })
    longitude: number

    @Field({ nullable: true })
    note: string

    @Field(() => Boolean, { nullable: true })
    ipValidation: boolean
}

@InputType()
export class CheckInHistoryFilter {
    @Field({ nullable: true, defaultValue: 0})
    page?: number

    @Field({ nullable: true, defaultValue: 20})
    size?: number

    @Field({ nullable: true })
    fromDate?: number

    @Field({ nullable: true })
    toDate?: number

    @Field(_type => CheckInStatus, { nullable: true })
    status?: CheckInStatus
}