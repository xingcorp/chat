import { Field, Float, Int, ObjectType, Parent, ResolveField, Resolver } from "@nestjs/graphql";
import { ProfileService } from "src/modules/graphql/profile/profile.service";
import {
    InfoBlock,
    OfficeOrgChart, OfficeTitle,
    OfficeUser,
    OrganizationDevice,
    UserAddress,
    UserBankAccount,
    UserDepartment, UserWorkProfile,
    UserWorkProfileInfo
} from "../../entities";
import { ObjectStatus } from "../../entities/profile.info.block";
import { User } from "../../../modules/core/iam/objects/user"
import { AddressType } from "../../entities/profile.address";
import { File } from "src/modules/core/storage/objects/file";
import { BearerAccessToken } from "src/modules/core/middleware/decorator/request.decorator";
import { StorageService } from "src/modules/core/storage/storage.service";
import { pluck } from "@utils/object.utils";
import { explainOfficeOrgChartToObj } from "@modules/graphql/management/orgchart/helpers/orgchart.helpers";
import { OfficeSysUser } from "@models/entities/system.user";
import { countMonthBetweenTwoDate } from "@utils/datetime.utils";
import { DefaultAvatar } from "@models/entities/default.avatar";
import { OfficeBlockType } from "@enum/block/block.enum";
import { InfoWorkProfileRepo, WorkProfileRepo } from "@models/repositories";
import { OrganizationDeviceStatus } from "@enum/device/device.enum";
import { RedisService } from "@core/common/redis.service";
import { RedisKey } from "@core/common/common.type";


@ObjectType()
export class UserListDepartment {
    @Field({ nullable: true })
    l1?: string;

    @Field({ nullable: true })
    l2?: string;

    @Field({ nullable: true })
    l3?: string;

    @Field({ nullable: true })
    l4?: string;

    @Field({ nullable: true })
    l5?: string;

    @Field({ nullable: true })
    l6?: string;

    @Field({ nullable: true })
    l7?: string;

    @Field({ nullable: true })
    l8?: string;
}

@Resolver(_of => OfficeUser)
export class OfficeUserFieldResolver {
    constructor(
        private readonly profileService: ProfileService,
        private readonly storageService: StorageService,
        private readonly workProfileRepo: WorkProfileRepo,
        private readonly infoWorkProfileRepo: InfoWorkProfileRepo,
        private readonly redisService: RedisService
    ) { }

    @ResolveField('address', _return => UserAddress, { nullable: true })
    async address(
        @Parent() root: OfficeUser
    ) {
        return UserAddress.findOne({
            where: {
                userId: root.id,
                addressType: AddressType.Permanent
            }
        })
    }

    // @ResolveField('organizationDevices', _return => [OrganizationDevice], { nullable: true })
    // async organizationDevice(
    //     @Parent() root: OfficeUser
    // ) {

    //     const result = await OrganizationDevice.find({
    //         where: {
    //             userId: root.id,
    //             status: OrganizationDeviceStatus.APPROVED
    //         }
    //     })

    //     return result;
    // }

    @ResolveField('tempAddress', _return => UserAddress, { nullable: true })
    async tempAddress(
        @Parent() root: OfficeUser
    ) {
        return UserAddress.findOne({
            where: {
                userId: root.id,
                addressType: AddressType.Temporary
            }
        })
    }

    @ResolveField('bankAccount', _return => UserBankAccount, { nullable: true })
    async bankAccount(
        @Parent() root: OfficeUser
    ) {
        return UserBankAccount.findOne({
            where: {
                userId: root.id
            }
        })
    }

    // @ResolveField('extraData', _return => GraphQLJSON, { nullable: true })
    // async extraData(
    //     @Parent() root: OfficeUser
    // ) {
    //     if (root.metadata && root.metadata[0]) {
    //         const data = root.metadata[0]
    //         const result = JSON.parse(data)
    //         const keys = Object.keys(result)
    //         for (const key of keys) {
    //             result[key] = {
    //                 value: result[key],
    //                 field: await InfoField.findOne({ where: { code: key } })
    //             }
    //         }
    //         return result
    //     }

    //     return null
    // }

    // @ResolveField('cmsData', _return => GraphQLJSON, { nullable: true })
    // async cmsData(
    //     @Parent() root: OfficeUser
    // ) {
    //     if (root.metadata && root.metadata[0]) {
    //         const fields = await this.profileService.getAllInfoFields()

    //         const data = JSON.parse(root.metadata[0])
    //         const result = {}

    //         fields.forEach(field => {
    //             result[field.code] = {
    //                 value: data[field.code],
    //                 field: field
    //             }
    //         });
    //         return result
    //     }

    //     return null
    // }

    @ResolveField('infoBlocks', _return => [InfoBlock], { nullable: true })
    async infoBlocks(
        @Parent() root: OfficeUser
    ) {
        const blocks = await InfoBlock.find({
            where: {
                relationType: OfficeBlockType.User
            },
            order: {
                order: "ASC"
            }
        })
        blocks.forEach(block => {
            block.officeUserExtraData = root.metadata && root.metadata[0] ? JSON.parse(root.metadata[0]) : null
        })
        return blocks
    }

    @ResolveField('appInfoBlocks', _return => [InfoBlock], { nullable: true })
    async appInfoBlocks(
        @Parent() root: OfficeUser
    ) {
        const blocks = await InfoBlock.find({
            where: {
                status: ObjectStatus.Active,
                relationType: OfficeBlockType.User
            },
            order: {
                order: "ASC"
            }
        })
        blocks.forEach(block => {
            block.officeUserExtraData = root.metadata && root.metadata[0] ? JSON.parse(root.metadata[0]) : null
        })
        return blocks
    }

    @ResolveField('attachFiles', _return => [File], { nullable: true })
    async attachFiles(
        @Parent() root: OfficeUser,
        @BearerAccessToken() token: string
    ) {
        const { data, error } = await this.storageService.getFilesDetail(token, root.attachFileIds)
        if (error) return []
        return data.files
    }

    @ResolveField('departments', _return => [UserDepartment], { nullable: true })
    async departments(
        @Parent() root: OfficeUser
    ) {
        return UserDepartment.find({
            where: {
                userId: root.id
            }
        })
    }

    @ResolveField('departmentName', _return => String, { nullable: true })
    async departmentName(
        @Parent() root: OfficeUser
    ) {
        const relation = await UserDepartment.findOne({
            where: {
                userId: root.id,
            },
            order: {
                createdAt: 'DESC'
            }
        })

        if (relation.departmentId) {
            const data = await OfficeOrgChart.findOne({
                where: { id: relation.departmentId }
            })

            return data.name
        }

        return null
    }

    @ResolveField('titleName', _return => String, { nullable: true })
    async titleName(
        @Parent() root: OfficeUser
    ) {
        const relation = await UserDepartment.findOne({
            where: {
                userId: root.id,
            },
            order: {
                createdAt: 'DESC'
            }
        })

        if (relation && relation.titleId) {
            const data = await OfficeTitle.findOne({
                where: { id: relation.titleId }
            })

            return data.name
        }

        return null
    }

    @ResolveField('company', _return => OfficeOrgChart, { nullable: true })
    async company(
        @Parent() root: OfficeUser
    ) {
        if (root.companyId) {
            return OfficeOrgChart.findOne({
                where: {
                    id: root.companyId
                }
            })
        }
        return null
    }

    @ResolveField('departmentLever', _return => UserListDepartment, { nullable: true })
    async departmentLever(
        @Parent() root: OfficeUser
    ) {
        const user = await OfficeUser.createQueryBuilder('qb')
            .leftJoinAndMapMany('qb.departments', UserDepartment, 'd', 'd."userId" = qb.id::text')
            .leftJoinAndMapOne('qb.department', OfficeOrgChart, 'dd', 'dd.id::text = d."departmentId"::text')
            .where('qb.id::text = :id', { id: root.id })
            .select([
                'qb.id',
                'qb.fullname',
                'dd.path',
            ])
            .getOne() as any

        const departments = pluck(await OfficeOrgChart.find(), 'name', 'id')

        return explainOfficeOrgChartToObj(user?.department?.path, departments)
    }

    @ResolveField('createdByUser', _return => OfficeSysUser, { nullable: true })
    async createdByUser(
        @Parent() root: OfficeUser
    ) {
        return await OfficeSysUser.findOne({ where: { id: root.createdBy } })
    }

    @ResolveField('updatedByUser', _return => OfficeSysUser, { nullable: true })
    async updatedByUser(
        @Parent() root: OfficeUser
    ) {
        return await OfficeSysUser.findOne({ where: { id: root.updatedBy } })
    }

    @ResolveField('leader', _return => OfficeUser, { nullable: true })
    async leader(
        @Parent() root: OfficeUser
    ) {
        if (root.leaderId) {
            return OfficeUser.findOne({
                where: {
                    id: root.leaderId
                }
            })
        }
        return null
    }

    @ResolveField('seniority', _return => Int, { nullable: true })
    async seniority(
        @Parent() root: OfficeUser
    ) {
        return countMonthBetweenTwoDate(root.onboardingOn, root.leaveOn, null)
    }

    @ResolveField('imageUrls', _return => [String], { nullable: true })
    async imageUrls(
        @Parent() root: OfficeUser
    ) {
        if (root.imageUrls && root.imageUrls.length > 0) return root.imageUrls
        let result = null
        // if (root.metadata && root.metadata.length > 0) {
        //     if (root.metadata[0].includes("Nam")) {
        //         const avatar = await DefaultAvatar.createQueryBuilder('da').where({ gender: 'Nam' }).orderBy('RANDOM()').getOne()
        //         if (avatar) result = [avatar.imageUrl]
        //     } else if (root.metadata[0].includes("Nữ")) {
        //         const avatar = await DefaultAvatar.createQueryBuilder('da').where({ gender: 'Nữ' }).orderBy('RANDOM()').getOne()
        //         if (avatar) result = [avatar.imageUrl]
        //     }
        // }

        return result
    }

    @ResolveField('workProfile', _return => UserWorkProfile, { nullable: true })
    async workProfile(
        @Parent() root: OfficeUser
    ) {
        const info = await this.infoWorkProfileRepo.getActiveRecordByUserIdAndDate(root.id)

        if (!info) return null

        return this.workProfileRepo.findOneBy({ id: info.workProfile.id })
    }

    @ResolveField('optionTitle', _return => String, { nullable: true })
    async optionTitle(
        @Parent() root: OfficeUser
    ) {
        const departmentName = await this.departmentName(root)
        const titleName = await this.titleName(root)

        return `${root.code} - ${root.fullname} - ${departmentName ?? 'Chưa có phòng ban'} - ${titleName ?? 'Chưa có chức danh'}`
    }

    @ResolveField('statusActive', _return => String, { nullable: true })
    async statusActive(
        @Parent() root: OfficeUser
    ) {
        if (!root.id) {
            return null
        }
        return this.redisService.get(RedisKey.UserStatus(root.id))
    }

    @ResolveField('offlineAt', _return => Float, { nullable: true })
    async offlineAt(
        @Parent() root: OfficeUser
    ) {
        if (!root.id) {
            return null;
        }
        return this.redisService.get(RedisKey.UserOfflineAt(root.id))
    }

}

@Resolver(_of => User)
export class UserFieldResolver {
    constructor(
        private readonly profileService: ProfileService
    ) { }

    @ResolveField('officeUser', _return => OfficeUser, { nullable: true })
    async officeUser(
        @Parent() root: User
    ) {
        return OfficeUser.findOne({
            where: {
                id: root.id
            }
        })
    }
}