import { Parent, registerEnumType, ResolveField, Resolver } from "@nestjs/graphql";
import { OfficeLogs, OfficeSysUser, OfficeUser } from "@models/entities";
import { RequesterRole } from "@common/enum.common";
import { getDataAdminToImpersonationUser } from "@helpers/data.helper";
import { File } from "@core/storage/objects/file";
import { RequestContext } from "@common/context/request.context";
import { forwardRef, Inject } from "@nestjs/common";
import { StorageService } from "@core/storage/storage.service";
import { RedisService } from "@core/common/redis.service";
import { OfficeAttachmentType } from "../../../arguments/logs/office-logs.args";
import { OfficeFeatureLogAttachmentType } from "@enum/logs/logs.enum";
import { LoggerService } from "@core/common/logger.service";

registerEnumType(RequesterRole, { name: 'RequesterRole' })

@Resolver(_of => OfficeLogs)
export class OfficeLogsResolver {
    logger = new LoggerService(OfficeLogsResolver.name)
    constructor(
        @Inject(forwardRef(() => StorageService))
        private readonly storageService: StorageService,
        private readonly redisService: RedisService,
    ) {
    }

    @ResolveField('creator', _return => OfficeUser, { nullable: true })
    async creator(
        @Parent() root: OfficeLogs
    ) {
        const _this = await OfficeLogs.findOne({
            relations: ['userCreator', 'adminCreator'],
            where: { id: root.id },
        })

        if (_this.userCreator) {
            return _this.userCreator
        }
        if (_this.adminCreator) {
            return {
                ...getDataAdminToImpersonationUser(_this.adminCreator)
            } as OfficeUser
        }

        return null
    }

    @ResolveField('userCreator', _return => OfficeUser, { nullable: true })
    async userCreator(
        @Parent() root: OfficeLogs
    ) {
        const _this = await OfficeLogs.findOne({
            relations: ['userCreator'],
            where: { id: root.id },
        })

        return _this.userCreator
    }

    @ResolveField('adminCreator', _return => OfficeSysUser, { nullable: true })
    async adminCreator(
        @Parent() root: OfficeLogs
    ) {
        const _this = await OfficeLogs.findOne({
            relations: ['adminCreator'],
            where: { id: root.id },
        })

        return _this.adminCreator
    }

    @ResolveField('creatorRole', _return => RequesterRole, { nullable: true })
    async creatorRole(
        @Parent() root: OfficeLogs
    ) {
        const _this = await OfficeLogs.findOne({
            relations: ['adminCreator'],
            where: { id: root.id },
        })

        if (_this.adminCreator) {
            return RequesterRole.Admin
        }

        return RequesterRole.User
    }

    @ResolveField('attachments', _return => [File], { nullable: true })
    async attachments(
        @Parent() root: OfficeLogs
    ) {
        this.logger.log(`root ${root.id} `);
        if (!root.objectIds) return null

        const redisKey = `log_comment_object_attachment_${root.id}`
        // await this.redisService.delete(redisKey)
        const cached = await this.redisService.get(redisKey)
        this.logger.log(`cached ${root.id} `, cached);
        if (cached) {
            const resCached = JSON.parse(cached)
            return resCached.length ? resCached : null
        }

        const res = await this.getDataObject(root, OfficeFeatureLogAttachmentType.Attachment)

        await this.redisService.setWithTtl(redisKey, JSON.stringify(res ?? []), 7 * 24 * 60 * 60)

        this.logger.log(`res ${root.id} `, cached);
        return res ?? null
    }

    @ResolveField('images', _return => [File], { nullable: true })
    async images(
        @Parent() root: OfficeLogs
    ) {
        if (!root.objectIds) return null

        const redisKey = `log_comment_object_image_${root.id}`
        // await this.redisService.delete(redisKey)
        const cached = await this.redisService.get(redisKey)
        if (cached) {
            const resCached = JSON.parse(cached)
            return resCached.length ? resCached : null
        }

        const res = await this.getDataObject(root, OfficeFeatureLogAttachmentType.Image)

        await this.redisService.setWithTtl(redisKey, JSON.stringify(res ?? []), 7 * 24 * 60 * 60)

        return res ?? null
    }

    private async getDataObject(root: OfficeLogs, type: OfficeFeatureLogAttachmentType) {
        const list = (root.objectType as any as OfficeAttachmentType[])
            .find(i => i.type === type)
            ?.list

        const { data } = await this.storageService.getFilesDetail(RequestContext.currentToken(), list)

        return data?.files
    }
}