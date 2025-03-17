import { OrganizationDeviceStatus } from "@enum/device/device.enum";
import { Field, InputType, Int } from "@nestjs/graphql";

@InputType()
export class OrgDeviceArgs {
    @Field({ nullable: false })
    name: string

    @Field({ nullable: false })
    model: string

    @Field({ nullable: false })
    identifierForVendor: string

    @Field(() => String, { nullable: true })
    versionOS: string

}




@InputType()
export class OrgDeviceFilter {
    @Field(_type => Int, { nullable: true, defaultValue: 0 })
    page: number;

    @Field(_type => Int, { nullable: true, defaultValue: 20 })
    size: number;

    @Field(_type => String, { nullable: true })
    keyword: string;

}