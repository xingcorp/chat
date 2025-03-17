import { OrganizationDevice } from "@models/entities/organization.device";
import { Args, Mutation, Query, Resolver } from "@nestjs/graphql";
import { OrgDeviceArgs, OrgDeviceFilter } from "./organization.devices.args";
import { RequesterId } from "@core/middleware/decorator/user.decorator";
import { Brackets, ILike, IsNull, Like } from "typeorm";
import { OrganizationDeviceResponse } from "./organization.device.response";
import { BaseError } from "@core/core.error";
import { OrganizationDeviceStatus } from "@enum/device/device.enum";
import { OfficeError } from "@common/office.error";
import { OrganizationDeviceService } from "./organization.device.service";
import { SetMetadata } from "@nestjs/common";
import { ServiceActions, ServiceKeys } from "@core/middleware/guard/service.action";
import { BearerAccessToken } from "@core/middleware/decorator/request.decorator";

@Resolver()
export class OrganizationDeviceResolver {
    constructor(private readonly organizationDeviceService: OrganizationDeviceService) { }

    @Mutation(_return => OrganizationDevice, { name: "registerOrganizationDevice", nullable: true })
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    async registerOrganizationDevice(
        @Args("argument") argument: OrgDeviceArgs,
        // @RequesterId() userId: string,
        @BearerAccessToken() token: string,
    ): Promise<OrganizationDevice> {
        return this.organizationDeviceService.registerOrganizationDevice(argument, token);
    }

    @Query(_return => OrganizationDeviceResponse, { name: "getListOrganizationDevices" })
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    async getListOrganizationDevice(
        @Args("filter", { nullable: true }) filter: OrgDeviceFilter,
        //@RequesterId() userId: string,   
    ): Promise<OrganizationDeviceResponse> {
        return this.organizationDeviceService.getListOrganizationDevices(filter);
    }

    @Mutation(_return => OrganizationDevice, { name: "approveNewDevices", nullable: true })
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    async approveNewDevice(
        @Args('id') id: string,
        @RequesterId() userId: string,
    ): Promise<OrganizationDevice> {
        return this.organizationDeviceService.approveNewDevice(userId, id);
    }


    @Query(_return => [OrganizationDevice], { name: "getListOrganizationDevicesApproved" })
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    async getListOrganizationDeviceHasApprove(
    ): Promise<OrganizationDevice[]> {
        return this.organizationDeviceService.getListDeviceHasApproved();
    }
}