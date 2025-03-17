import { Parent, ResolveField, Resolver } from "@nestjs/graphql";
import {
    VersionWiki,
    OfficeLogs,
    OfficeUser,
    OfficeApproval,
    DocumentWiki,
    TagDocument, CategoryWiki
} from "@models/entities";
import { forwardRef, Inject } from "@nestjs/common";
import { StorageService } from "@core/storage/storage.service";
import { OfficeFeatureLogType, OfficeLogType } from "@enum/logs/logs.enum";
import { File } from "@core/storage/objects/file";
import { RequestContext } from "@common/context/request.context";
import { CACHE_KEY } from "@common/cache-key.common";
import { RedisService } from "@core/common/redis.service";
import { InjectRepository } from "@nestjs/typeorm";
import { VersionWikiRepo } from "@models/repositories";
import { ApprovalType } from "@models/entities/approval.form";
import { LoggerService } from "@core/common/logger.service";

@Resolver(_of => VersionWiki)
export class VersionWikiResolver {
    private readonly logger = new LoggerService(VersionWikiResolver.name)
    constructor(
        @Inject(forwardRef(() => StorageService))
        private readonly storageService: StorageService,
        private readonly redisService: RedisService,
        @InjectRepository(VersionWikiRepo)
        private versionWikiRepo: VersionWikiRepo,
    ) {
    }

    @ResolveField('wiki', _return => DocumentWiki, { nullable: true })
    async wiki(
        @Parent() root: VersionWiki
    ) {
        const _root = await this.versionWikiRepo.getBy({ id: root.id }, ['wiki'])
        return _root.wiki
    }

    @ResolveField('approval', _return => OfficeApproval, { nullable: true })
    async approval(
        @Parent() root: VersionWiki
    ) {
        return OfficeApproval.createQueryBuilder()
            .where({
                type: ApprovalType.WikiRelease,
                relationId: root.id
            })
            .getOne()
    }

    @ResolveField('userCreator', _return => OfficeUser, { nullable: true })
    async userCreator(
        @Parent() root: VersionWiki
    ) {
        const _root = await this.versionWikiRepo.getBy({ id: root.id }, ['userCreator'])
        return _root.userCreator
    }

    @ResolveField('versionRevert', _return => VersionWiki, { nullable: true })
    async versionRevert(
        @Parent() root: VersionWiki
    ) {
        const _root = await this.versionWikiRepo.getBy({ id: root.id }, ['versionRevert'])
        return _root.versionRevert
    }

    @ResolveField('lastVersion', _return => VersionWiki, { nullable: true })
    async lastVersion(
        @Parent() root: VersionWiki
    ) {
        const _root = await this.versionWikiRepo.getBy({ id: root.id }, ['lastVersion'])
        return _root.lastVersion
    }

    @ResolveField('thumbnails', _return => [File], { nullable: true })
    async thumbnails(
        @Parent() root: VersionWiki
    ) {
        if (!root.thumbnailIds || !root.thumbnailIds?.length) return null

        const cacheKey = CACHE_KEY.WIKI.VERSION.THUMBNAIL(root.id)
        let cached = await this.redisService.get(cacheKey)

        if (cached) {
            return typeof cached === 'object' ? cached : JSON.parse(cached)
        }

        const { data } = await this.storageService.getFilesDetail(RequestContext.currentToken(), root.thumbnailIds)

        const res = data?.files ?? []

        await this.redisService.set(cacheKey, JSON.stringify(res))

        return res
    }

    @ResolveField('attachments', _return => [File], { nullable: true })
    async attachments(
        @Parent() root: VersionWiki
    ) {
        if (!root.attachmentIds || !root.attachmentIds?.length) return null

        const cacheKey = CACHE_KEY.WIKI.VERSION.ATTACHMENT(root.id)

        let cached = await this.redisService.get(cacheKey)

        if (cached) {
            return typeof cached === 'object' ? cached : JSON.parse(cached)
        }

        const { data } = await this.storageService.getFilesDetail(RequestContext.currentToken(), root.attachmentIds)

        const res = data?.files ?? []

        await this.redisService.set(cacheKey, JSON.stringify(res))

        return res
    }

    @ResolveField('comments', _return => [OfficeLogs], { nullable: true })
    comments(
        @Parent() root: VersionWiki
    ) {
        return OfficeLogs.find({
            where: {
                featureLogType: OfficeFeatureLogType.VersionWiki,
                featureLogId: root.id,
                type: OfficeLogType.Comment,
            },
            order: {
                createdAt: 'ASC'
            }
        })
    }

    @ResolveField('tags', _return => [TagDocument], { nullable: true })
    async tags(
        @Parent() root: VersionWiki
    ) {
        if (root.tags) {
            return root.tags;
        }
        const versionWiki = await VersionWiki.createQueryBuilder('version')
            .leftJoinAndSelect('version.tags', 'tags')
            .where('version.id = :id', { id: root.id })
            .getOne()

        if (!versionWiki) return []

        return versionWiki.tags;
    }

    @ResolveField('categories', _return => [CategoryWiki], { nullable: true })
    async categories(
        @Parent() root: DocumentWiki
    ) {
        try {
            const _root = await this.versionWikiRepo.getBy({ id: root.id }, ['wiki'])
            if (!_root.wiki) return []

            const wiki = await DocumentWiki.createQueryBuilder('qb')
                .leftJoinAndSelect('qb.categories', 'categories')
                .where({
                    id: _root.wiki.id
                })
                .getOne()

            return wiki?.categories
        } catch (error) {
            this.logger.error('[VersionWikiResolver] Error get categories', error)
            return []
        }
    }
}