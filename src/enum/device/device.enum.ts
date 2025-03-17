import { registerEnumType } from "@nestjs/graphql";

export enum OrganizationDeviceStatus {
    APPROVED = 'APPROVED',
    REQUEST = 'REQUEST'
}

registerEnumType(OrganizationDeviceStatus, { name: 'OrganizationDeviceStatus' });
