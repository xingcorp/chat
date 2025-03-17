import { Parent, ResolveField, Resolver } from "@nestjs/graphql";
import { OfficeTaskLog } from "@models/entities";
import { File } from "@core/storage/objects/file";
import { OfficeFeatureLogAttachmentType } from "@enum/logs/logs.enum";
import { forwardRef, Inject } from "@nestjs/common";
import { StorageService } from "@core/storage/storage.service";
import { RedisService } from "@core/common/redis.service";
import { OfficeAttachmentType } from "../../../arguments/logs/office-logs.args";
import { RequestContext } from "@common/context/request.context";

@Resolver(_of => OfficeTaskLog)
export class OfficeTaskLogFieldResolver {
    constructor(
        @Inject(forwardRef(() => StorageService))
        private readonly storageService: StorageService,
        private readonly redisService: RedisService,
    ) {
    }

    @ResolveField('attachments', _return => [File], { nullable: true })
    async attachments(
        @Parent() root: OfficeTaskLog
    ) {
        if (!root.objectIds || !root.objectIds.length) return []

        const redisKey = `task_comment_object_attachment_${root.id}`
        // await this.redisService.delete(redisKey)
        const cached = await this.redisService.get(redisKey)
        if (cached) {
            const resCached = JSON.parse(cached)
            return resCached.length ? resCached : []
        }

        const res = await this.getDataObject(root, OfficeFeatureLogAttachmentType.Attachment)

        await this.redisService.setWithTtl(redisKey, JSON.stringify(res ?? []), 30 * 24 * 60 * 60)

        return res ?? []
    }

    @ResolveField('images', _return => [File], { nullable: true })
    async images(
        @Parent() root: OfficeTaskLog
    ) {
        if (!root.objectIds || !root.objectIds.length) return []

        const redisKey = `task_comment_object_image_${root.id}`
        // await this.redisService.delete(redisKey)
        const cached = await this.redisService.get(redisKey)
        if (cached) {
            const resCached = JSON.parse(cached)
            return resCached.length ? resCached : []
        }

        const res = await this.getDataObject(root, OfficeFeatureLogAttachmentType.Image)

        await this.redisService.setWithTtl(redisKey, JSON.stringify(res ?? []), 30 * 24 * 60 * 60)

        return res ?? []
    }

    private async getDataObject(root: OfficeTaskLog, type: OfficeFeatureLogAttachmentType) {
        let objectType = root.objectType
        if (typeof objectType === 'string') objectType = JSON.parse(objectType)

        const list = (objectType as any as OfficeAttachmentType[])
            .find(i => i.type === type)
            ?.list

        const { data } = await this.storageService.getFilesDetail(RequestContext.currentToken(), list)

        return data?.files ?? []
    }
}