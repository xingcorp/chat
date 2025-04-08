import { PagingData } from "@models/base/paging.response"
import { OrganizationDevice } from "@models/entities/organization.device"
import { OfficeUser } from "@models/entities/profile.user"
import { Field, ObjectType } from "@nestjs/graphql"

// @ObjectType({ implements: PagingData })
// export class OrganizationDeviceResponse implements PagingData {
//     total: number
//     count: number

//     @Field(_type => [OrganizationDevice], { nullable: true })
//     result?: OrganizationDevice[]
// }


@ObjectType({ implements: PagingData })
export class OrganizationDeviceResponse implements PagingData {
    total: number
    count: number

    @Field(type => [OrganizationDevice], { nullable: true })
    result?: OrganizationDevice[];
}

@ObjectType()
export class Device {
    @Field(_type => OfficeUser)
    user: OfficeUser;

    @Field({ nullable: true })
    employeeName: string;

    @Field({ nullable: true })
    employeeCode: string;

    @Field({ nullable: true })
    deviceNameApprove?: string;

    @Field({ nullable: true })
    deviceNameRequest?: string;

    @Field({ nullable: true })
    identifierForVendorApprove?: string;

    @Field({ nullable: true })
    identifierForVendorRequest?: string;

    @Field({ nullable: true })
    approveAt?: Date;

    @Field({ nullable: true })
    requestAt?: Date;
}