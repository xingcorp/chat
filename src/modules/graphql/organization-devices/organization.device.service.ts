import { OrganizationDeviceStatus } from "@enum/device/device.enum";
import { OfficeOrgChart, OfficeUser, OrganizationDevice, UserDepartment } from "@models/entities";
import { Injectable } from "@nestjs/common";
import { OrgDeviceArgs, OrgDeviceFilter } from "./organization.devices.args";
import { Brackets, In, IsNull } from "typeorm";
import { OfficeError } from "@common/office.error";
import { RandomHelper } from "@common/random";
import { IdentityService } from "@core/iam/identity/identity.service";


@Injectable()
export class OrganizationDeviceService {
    constructor(
        private readonly identityService: IdentityService,
    ) { }

    async registerOrganizationDevice(argument: OrgDeviceArgs, token: string): Promise<OrganizationDevice> {
        const requestId = RandomHelper.generateUUID()
        const user = await this.identityService.userProfile(token, requestId)
        const officeUser = await OfficeUser.findOne({ where: { iamUserId: user.id } })
        // const userDepartments = await UserDepartment.find({
        //     where: {
        //         userId: officeUser.id,
        //     }
        // })
        // let rootIds = []
        // const departments = await OfficeOrgChart.find({
        //     where: {
        //         id: In(userDepartments.map(ud => ud.departmentId))
        //     }
        // })
        // for (const dept of departments) {
        //     const root = dept.path.split("/")[1]
        //     if (!rootIds.includes(root)) rootIds.push(root)
        // }

        // if (!rootIds.includes(process.env.OXII_ORG_ID)) {
        //     throw OfficeError.OrgChartNotAlowThisFeature
        // }

        const checkApprovedDevice = await OrganizationDevice.findOne({
            where: {
                userId: officeUser.id,
                status: OrganizationDeviceStatus.APPROVED,
            }
        });

        if (checkApprovedDevice) {
            if (checkApprovedDevice.identifierForVendor === argument.identifierForVendor) {
                checkApprovedDevice.name = argument.name ? argument.name : checkApprovedDevice.name;
                checkApprovedDevice.model = argument.model ? argument.model : checkApprovedDevice.model;
                checkApprovedDevice.versionOS = argument.versionOS ? argument.versionOS : checkApprovedDevice.versionOS;
                return checkApprovedDevice.save();
            } else {
                const requestNewDevice = OrganizationDevice.create({
                    userId: officeUser.id,
                    name: argument.name,
                    model: argument.model,
                    identifierForVendor: argument.identifierForVendor,
                    versionOS: argument.versionOS,
                    status: OrganizationDeviceStatus.REQUEST,
                    createdBy: officeUser.id,
                    updatedBy: officeUser.id,
                });

                await OrganizationDevice.update({
                    userId: officeUser.id,
                    status: OrganizationDeviceStatus.REQUEST,
                    deletedAt: IsNull()
                }, {
                    updatedBy: officeUser.id,
                    deletedAt: new Date()
                });
                return requestNewDevice.save();
            }
        } else {
            const approvedNewDevice = OrganizationDevice.create({
                userId: officeUser.id,
                name: argument.name,
                model: argument.model,
                identifierForVendor: argument.identifierForVendor,
                versionOS: argument.versionOS,
                status: OrganizationDeviceStatus.APPROVED,
                approvedAt: new Date(),
                createdBy: officeUser.id,
                updatedBy: officeUser.id,
            });
            return approvedNewDevice.save();
        }
    }

    async getListOrganizationDevices(filter: OrgDeviceFilter,) {
        if (!filter.page) filter.page = 0;
        if (!filter.size) filter.size = 20;


        const organizationDeviceQueryBuilder = OrganizationDevice.createQueryBuilder('organizationDevice')
            .leftJoinAndSelect('organizationDevice.user', 'user')
            .where('organizationDevice.deletedAt IS NULL');
        if (filter.keyword) {
            organizationDeviceQueryBuilder.andWhere(new Brackets(qb => {
                qb.orWhere("user.code ILIKE :keyword", { keyword: `%${filter.keyword}%` })
                    .orWhere("user.fullname ILIKE :keyword", { keyword: `%${filter.keyword}%` })
                    .orWhere("organizationDevice.name ILIKE :keyword", { keyword: `%${filter.keyword}%` })
                    .orWhere("organizationDevice.identifierForVendor ILIKE :keyword", { keyword: `%${filter.keyword}%` });
            }));
        }
        console.log('check', organizationDeviceQueryBuilder.getSql())
        const [devices, total] = await organizationDeviceQueryBuilder
            .orderBy('organizationDevice.createdAt', 'DESC')
            .skip(filter.page * filter.size)
            .take(filter.size)
            .getManyAndCount();

        return {
            total: total,
            count: devices.length,
            result: devices
        }

    }

    async approveNewDevice(userId: string, id: string) {

        const deviceExisted = await OrganizationDevice.findOne({
            where: {
                id: id
            }
        })
        if (!deviceExisted) {
            throw OfficeError.NotFoundDevice
        }
        if (deviceExisted.status === OrganizationDeviceStatus.APPROVED) {
            throw OfficeError.DeviceHasApproved
        }

        deviceExisted.status = OrganizationDeviceStatus.APPROVED
        deviceExisted.updatedBy = userId
        deviceExisted.adminUpdatedAt = new Date()
        deviceExisted.approvedAt = new Date()

        await OrganizationDevice.update({
            userId: deviceExisted.userId,
            // businessRoleId: deviceExisted.businessRoleId,
            status: OrganizationDeviceStatus.APPROVED
        }, {
            updatedBy: userId,
            deletedAt: new Date()
        })

        return deviceExisted.save()
    }

    async getListDeviceHasApproved() {
        return OrganizationDevice.find({
            where: {
                status: OrganizationDeviceStatus.APPROVED
            }
        })

    }

}