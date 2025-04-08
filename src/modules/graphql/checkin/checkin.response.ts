import { Field, Int, ObjectType } from "@nestjs/graphql"
import { PagingData } from "src/models/base/paging.response"
import { CheckIn, CheckInPlace, WhitelistIP } from "src/models/entities"

@ObjectType()
export class WhitelistAddIpResponse {
    @Field(_type => Int, { nullable: false, defaultValue: 0 })
    total: number

    @Field(_type => Int, { nullable: false, defaultValue: 0 })
    insertedCount: number

    @Field(_type => Int, { nullable: false, defaultValue: 0 })
    existedCount: number

    @Field(_type => [String], { nullable: true })
    existedIPs?: string[]
    
    @Field(_type => [WhitelistIP], { nullable: true })
    insertedIPs?: WhitelistIP[]
}

@ObjectType()
export class WhitelistRemoveIpResponse {
    @Field(_type => Int, { nullable: false, defaultValue: 0 })
    total: number

    @Field(_type => Int, { nullable: false, defaultValue: 0 })
    removedCount: number
    
    @Field(_type => [WhitelistIP], { nullable: true })
    removedIPs?: WhitelistIP[]
}

@ObjectType({ implements: PagingData })
export class WhitelistIPResponse implements PagingData {
    total: number
    count: number
    
    @Field(_type => [WhitelistIP], { nullable: true })
    publicIps?: WhitelistIP[]
}

@ObjectType({ implements: PagingData })
export class CheckInPlaceResponse implements PagingData {
    total: number
    count: number
    
    @Field(_type => [CheckInPlace], { nullable: true })
    places?: CheckInPlace[]
}

@ObjectType()
export class CheckInInfo {
    @Field(_type => Int)
    workingTime: number
    
    @Field({ nullable: false, defaultValue: false })
    isValid: boolean
}

@ObjectType({ implements: PagingData })
export class CheckInResponse implements PagingData {
    total: number
    count: number
    
    @Field(_type => [CheckIn], { nullable: true })
    checkIns?: CheckIn[]
}