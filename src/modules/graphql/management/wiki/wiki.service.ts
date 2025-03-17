import { Injectable } from '@nestjs/common';
import {
    ManageWikiFilter,
    OfficeWikiFilter,
    VersionWikiCommentCreateInput,
    VersionWikiCopyCreateInput, WikiCommentCreateInput,
    WikiCopyCreateInput,
    WikiCreateInput, WikiInfoUpdateInput,
    WikiMoveInput,
    WikiNewVersionCreateInput, WikiNewVersionRevertInput,
    WikiSetImportantInput,
    WikiUpdateInput
} from "@modules/graphql/management/wiki/dto/wiki.args";
import { WikiRepo } from "@repositories/wiki/wiki.repo";
import { ApprovalService } from "@modules/graphql/approval/approval.service";
import { VersionWikiRepo } from "@models/repositories";
import { DataSource, In } from "typeorm";
import { DocumentFolder, DocumentWiki, OfficeApproval, OfficeUser, VersionWiki, Viewer } from "@models/entities";
import { RequestContext } from "@common/context/request.context";
import { OfficeError } from "@common/office.error";
import { VersionWikiStatus, WikiStatus } from "@enum/wiki/wiki.enum";
import { OfficeLogCommentArgs } from "@modules/graphql/log/dto/log.args";
import { LogService } from "@modules/graphql/log/log.service";
import { OfficeOrgChartDocumentRepo } from "@repositories/office-org-chart-document.repo";
import { CACHE_KEY } from "@common/cache-key.common";
import { RedisService } from "@core/common/redis.service";
import { ApprovalProcessAction } from "@models/entities/approval.step";
import { ApprovalActionArgs, ApprovalArgs } from "@modules/graphql/approval/approval.args";
import { ApprovalSubmitTypeEnum } from "@enum/approval/approval/approval.enum";
import { ApprovalType } from "@models/entities/approval.form";
import { WIKI_COPY_VERSION } from "../../../../constant/wiki.const";
import { ViewerService } from "@modules/graphql/viewer/viewer.service";
import { ApprovalStatus } from "@models/entities/approval";
import { ViewerTypeEnum, ViewTypeEnum } from "@enum/viewer/viewer.enum";
import { arrayConvertToDistinctAndNotNull } from "@utils/array.utils";
import { DocumentType } from "@models/entities/org.chart.document";

const MAX_LATEST_WIKI_RETURN = 10

@Injectable()
export class WikiService {

    constructor(
        private dataSource: DataSource,
        private readonly wikiRepo: WikiRepo,
        private readonly versionWikiRepo: VersionWikiRepo,
        private readonly approvalService: ApprovalService,
        private readonly logService: LogService,
        private readonly orgChartDocumentRepo: OfficeOrgChartDocumentRepo,
        private readonly redisService: RedisService,
        private readonly viewerService: ViewerService,
    ) {
    }

    private async checkAndGetUserAction() {
        const user = await RequestContext.currentUser()

        if (!user) {
            throw OfficeError.AdminNeedLinkUser
        }

        return user
    }

    async wikiUpsert(args: WikiCreateInput | WikiUpdateInput, user: OfficeUser) {
        let wiki: DocumentWiki

        if (args['wiki']) {
            wiki = args['wiki']
            wiki.updatedBy = RequestContext.currentRequestId()

            if (args.status === VersionWikiStatus.Draft) {
                wiki.name = args.name ?? wiki.name
                wiki.code = args.code ?? wiki.code
            }
        } else {
            wiki = this.wikiRepo.create({
                name: args.name,
                code: args.code
            })
            wiki.createdBy = RequestContext.currentRequestId()
            wiki.userCreator = user
        }

        wiki.folder = args.folder
        wiki.orgCharts = await RequestContext.getRootOrgs()

        if (args.important) {
            wiki.important = args.important
        }

        if (args.categoryWikis) {
            wiki.categories = args.categoryWikis
        }

        if (args.tags) {
            wiki.tags = args.tags
        }

        return wiki
    }

    private async versionWikiCreate(wiki: DocumentWiki, args: WikiCreateInput | WikiNewVersionCreateInput, user: OfficeUser) {
        let versionWiki: VersionWiki

        if (args['versionWiki']) {
            versionWiki = args['versionWiki']

            versionWiki.name = args.name
            versionWiki.code = args.code ?? null
            versionWiki.content = args.content
            versionWiki.thumbnailIds = args.thumbnailIds
            versionWiki.attachmentIds = args.attachmentIds
            versionWiki.status = args.status
            versionWiki.updateType = args['updateType'] ?? null
            versionWiki.updatedBy = RequestContext.currentRequestId()

            await this.versionWikiRemoveCache(versionWiki)

        } else {
            versionWiki = this.versionWikiRepo.createNew(args)
        }

        versionWiki.wiki = wiki
        versionWiki.userCreator = user
        versionWiki.tags = args.tags

        if (args.versionRevert) versionWiki.versionRevert = args.versionRevert

        return versionWiki
    }

    async create(args: WikiCreateInput) {
        const user = await this.checkAndGetUserAction()

        const wiki = await this.wikiUpsert(args, user)

        await this.checkIsDraft(args, wiki)

        await wiki.save()

        await this.versionWikiUpsert(args, wiki, user)

        return wiki;
    }

    async update(args: WikiUpdateInput) {
        if (args.versionDraft) {
            if (args.approval && args.approval.status === ApprovalStatus.Draft) {
                args.approvalArgs.draftId = args.approvalId
                delete args.approval
            }
            if (args.versionWiki) {
                delete args.versionWiki
            }
        }

        return this.create(args)
    }

    async versionCreate(args: WikiNewVersionCreateInput) {
        const user = await this.checkAndGetUserAction()

        const wiki = args.wiki

        await this.versionWikiUpsert(args, wiki, user);

        return wiki
    }

    private async versionWikiUpsert(args: WikiCreateInput | WikiNewVersionCreateInput | WikiUpdateInput, wiki: DocumentWiki, user: OfficeUser = null) {
        if (!user) {
            user = await this.checkAndGetUserAction()
        }

        if (!wiki) {
            wiki = args['wiki'] ?? null

            if (!wiki.orgCharts) wiki.orgCharts = await RequestContext.getRootOrgs()
        }

        const versionWiki = await this.versionWikiCreate(wiki, args, user)

        await this.removeDraftVersion(args.versionDraft, args.status)

        await versionWiki.save()

        if (args.versionRevert && !args.approvalArgs) {
            await this.approvalService.copyApprovalByVersionId(args.versionRevert.id, versionWiki.id)
        } else {
            let approval: OfficeApproval = args['approval'] ?? null
            if (args.approvalArgs) {
                await this.approvalService.submitApproval({
                    ...args.approvalArgs,
                    type: ApprovalType.WikiRelease,
                    relationId: versionWiki?.id
                }, null, approval)
            }
        }

        if (args.permissions) {
            await this.infoUpdate({
                wikiId: wiki.id,
                wiki,
                permissions: args.permissions
            })
        }

        return versionWiki
    }

    async get(id: string) {
        const folderIds = await this.orgChartDocumentRepo.getAllDocIdsOfSys()

        const wiki = await this.wikiRepo.getBy(
            {
                id,
                folder: { id: In(folderIds || []) }
            },
            ['tags']
        );

        if (wiki && wiki.isPublic && RequestContext.isNormalUser()) {
            const viewer = await this.viewerService.userHasViewingWiki(wiki.id)

            if (viewer.count === 1) {
                wiki.viewCount++
                await wiki.save()
            }
        }

        return wiki
    }

    async list(filter: ManageWikiFilter) {
        const folderIds = await this.orgChartDocumentRepo.getAllDocIdsOfSys()
        const [data, total] = await this.wikiRepo.listByFilter(filter, folderIds)

        return {
            total: total as number,
            count: data.length,
            records: data
        }
    }

    async remove(id: string) {
        const folderIds = await this.orgChartDocumentRepo.getAllDocIdsOfSys()
        const wiki = await this.wikiRepo.getById(id, folderIds)

        if (!wiki) {
            throw OfficeError.DocumentWikiNotFound
        }

        if (wiki.status !== WikiStatus.Draft) {
            throw OfficeError.DocumentWikiCannotRemove
        }

        wiki.updatedBy = RequestContext.currentRequestId()
        await wiki.save()
        await wiki.softRemove()

        return id;
    }

    async versionRecall(versionWikiId: string) {
        const versionWiki = await this.versionWikiRepo.waitingApprovalGetById(versionWikiId)

        if (!versionWiki) {
            throw OfficeError.DocumentWikiNotFound
        }

        const approval = await this.approvalService.getOfVersionWikiId(versionWiki?.id)

        if (!approval) {
            throw OfficeError.ApprovalNotFound
        }

        await this.approvalService.updateApprovalAction(
            {
                action: ApprovalProcessAction.Cancel,
                id: approval.id
            } as ApprovalActionArgs
        )

        return versionWiki;
    }

    adminVersionCommentCreate(args: VersionWikiCommentCreateInput) {
        return this.versionCommentCreate(args)
    }

    private async versionCommentCreate(args: VersionWikiCommentCreateInput) {
        let param: any = args
        const versionWiki = args.versionWiki

        param.featureLogId = args.versionWikiId
        param.description = args.comment

        await this.logService.versionWikiCommentCreate(param as OfficeLogCommentArgs)

        return versionWiki;
    }

    adminWikiCommentCreate(args: WikiCommentCreateInput) {
        return this.commentCreate(args);
    }

    private async commentCreate(args: WikiCommentCreateInput) {
        let param: any = args
        const wiki = args.wiki

        param.featureLogId = args.wikiId
        param.description = args.comment

        await this.logService.wikiCommentCreate(param as OfficeLogCommentArgs)

        return wiki;
    }

    /*Client*/
    async clientGet(id: string, documentPermissions: any) {
        const wiki = await this.wikiRepo.getById(id, documentPermissions.folderIds || []);

        if (!wiki) {
            throw OfficeError.DocumentWikiNotFound
        }

        await this.viewerService.userHasViewingWiki(wiki.id)

        const viewer = await this.viewerService.userHasViewingVersionWiki((wiki.versions.find(i => i.isLatestVersion))?.id)

        if (viewer?.count === 1) {
            wiki.viewCount++
            await wiki.save()
        }

        return wiki
    }

    async clientList(filter: OfficeWikiFilter, documentPermissions: any) {
        const [data, total] = await this.wikiRepo.listByFilter(filter, documentPermissions.folderIds || [])

        return {
            total: total as number,
            count: data.length,
            records: data
        }
    }

    private async clientLatestListSet(wiki: DocumentWiki) {

        const cacheKey = CACHE_KEY.WIKI.LATEST_LIST(await RequestContext.currentId())
        let cached = await this.redisService.get(cacheKey)

        if (cached) {
            await this.redisService.set(cacheKey, [...new Set([
                wiki,
                ...(typeof cached === 'object' ? cached : JSON.parse(cached)).filter(i => i.id !== wiki.id)
            ].slice(0, MAX_LATEST_WIKI_RETURN))] as DocumentWiki[])
        } else {
            await this.redisService.set(cacheKey, [wiki])
        }
    }

    async clientLatestList(documentPermissions: any) {
        const [list, total] = await this.wikiRepo.listByFilter(null, documentPermissions.folderIds || [])
        if (!total) return null
        const viewers = await Viewer.createQueryBuilder('qb')
            .where({
                relationType: ViewTypeEnum.Wiki,
                relationId: In(list.map(i => i.id)),
                viewerType: ViewerTypeEnum.User,
                viewerId: await RequestContext.currentId()
            })
            .orderBy('qb.updatedAt', 'DESC')
            .take(10)
            .getMany()
        const wikis = await this.wikiRepo.getManyBy({ id: In(viewers.map(i => i.relationId)) })

        let res = []
        for (const viewer of viewers) {
            res.push(wikis.find(i => i.id === viewer.relationId))
        }

        res = arrayConvertToDistinctAndNotNull(res)

        return {
            total: res.length,
            count: res.length,
            records: res
        }
    }

    clientWikiCommentCreate(args: WikiCommentCreateInput) {
        return this.commentCreate(args)
    }

    clientVersionCommentCreate(args: VersionWikiCommentCreateInput) {
        return this.versionCommentCreate(args)
    }

    private async removeDraftVersion(versionDraft: VersionWiki, status: VersionWikiStatus) {
        if (versionDraft && status !== VersionWikiStatus.Draft) {
            await versionDraft.softRemove()
        }
    }

    private async checkIsDraft(args: WikiCreateInput | WikiUpdateInput, wiki?: DocumentWiki) {
        if (args.status === VersionWikiStatus.Draft) {
            if (wiki) wiki.status = WikiStatus.Draft

            if (args.approvalArgs) {
                args.approvalArgs.submitType = ApprovalSubmitTypeEnum.Draft
                args.approvalArgs.isPublic = false
            }

        } else {
            if (wiki) wiki.status = WikiStatus.Active

            if (args.approvalArgs) {
                args.approvalArgs.submitType = ApprovalSubmitTypeEnum.Submit
                args.approvalArgs.isPublic = true
            }
        }
    }

    async setImportant(args: WikiSetImportantInput) {
        const wiki = args.wiki

        wiki.important = args.important
        wiki.updatedBy = await RequestContext.currentId()

        await wiki.save()

        return wiki
    }

    async copy(args: WikiCopyCreateInput) {
        let version = await this.versionWikiRepo.getLatestVersionOfWiki(args.wikiId, ['wiki'])

        if (version) {
            version = await this.versionWikiRepo.getNewestVersionOfWiki(args.wikiId, ['wiki'])
        }

        return this.versionCopy({
            versionWikiId: version.id,
            versionWiki: version,
            ...args
        })
    }

    async versionCopy(args: VersionWikiCopyCreateInput) {
        const versionWiki = args.versionWiki
        const wiki = await this.wikiRepo.getBy({
            id: versionWiki.wiki.id
        }, ['versions', 'categories', 'tags'])

        const wikis = []
        for (const folder of args.folders) {
            wikis.push(await this.versionCopyToFolder(versionWiki, wiki, folder))
        }

        return wikis
    }

    private async versionCopyToFolder(versionWiki: VersionWiki, wikiOrigin: DocumentWiki, folder: DocumentFolder) {
        const wikiCopy = await this.wikiCopyCreate(wikiOrigin, folder)

        await wikiCopy.reload()

        const versionCopy = await this.versionCopyCreate(versionWiki, wikiCopy)

        const approval = await this.approvalService.getOfVersionWikiId(versionWiki.id)

        await this.approvalService.approvalCopyToDraftCreate(approval.id, versionCopy.id)

        return wikiOrigin
    }

    async wikiCopyCreate(wikiOrigin: DocumentWiki, folder: DocumentFolder) {
        const requestId = RequestContext.currentRequestId()
        const user = await RequestContext.currentUser()

        const wikiCopy = structuredClone(wikiOrigin)

        delete wikiCopy.id
        delete wikiCopy.no
        delete wikiCopy.createdAt
        delete wikiCopy.updatedAt
        delete wikiCopy.updatedBy

        wikiCopy.name = await this.getNameForCopy(wikiOrigin, folder)
        wikiCopy.createdBy = requestId
        wikiCopy.isPublic = false
        wikiCopy.status = WikiStatus.Draft
        wikiCopy.folder = folder
        wikiCopy.versions = null
        wikiCopy.userCreator = user

        await wikiCopy.save()

        return wikiCopy
    }

    private async getNameForCopy(wiki: DocumentWiki, folder: DocumentFolder) {
        const wikis = await this.wikiRepo.getAllNameStartOfFolderByFolderId(folder.id, wiki.name)
        const listName = wikis.map(i => i.name)
        const copyText = 'copy'

        let name = `${wiki.name} - ${copyText}`
        let count = 0
        let copyName = ''

        do {
            if (count) {
                copyName = `${name} ${count}`
            } else {
                copyName = name
            }

            count++;
        } while (listName.includes(copyName))

        return copyName
    }

    private async versionCopyCreate(versionWikiOrigin: VersionWiki, wikiCopy: DocumentWiki) {
        const requestId = RequestContext.currentRequestId()
        const user = await RequestContext.currentUser()

        const versionCopy = structuredClone(versionWikiOrigin)

        delete versionCopy.id
        delete versionCopy.no
        delete versionCopy.createdAt
        delete versionCopy.updatedAt
        delete versionCopy.updatedBy

        versionCopy.version = WIKI_COPY_VERSION
        versionCopy.updateType = null
        versionCopy.name = wikiCopy.name
        versionCopy.isPublic = false
        versionCopy.isLatestVersion = false
        versionCopy.status = VersionWikiStatus.Draft
        versionCopy.createdBy = requestId
        versionCopy.wiki = wikiCopy
        versionCopy.userCreator = user
        versionCopy.versionRevert = null
        versionCopy.lastVersion = null

        await versionCopy.save()

        return versionCopy
    }

    async move(args: WikiMoveInput) {
        const wiki = args.wiki
        wiki.folder = args.folder

        await wiki.save()

        return wiki;
    }

    private async versionWikiRemoveCache(versionWiki: VersionWiki) {
        const cacheKey = CACHE_KEY.WIKI.VERSION.THUMBNAIL(versionWiki.id)

        await this.redisService.delete(cacheKey)
    }

    async versionRevert(args: WikiNewVersionRevertInput) {
        const revert = args.versionRevert

        if (revert.status !== VersionWikiStatus.Approved) {
            throw OfficeError.VersionWikiNotApprovalCannotRevert
        }

        if (!(await revert.wiki.isCanCreateNewVersion())) {
            throw OfficeError.DocumentWikiCanNotCreateNewVer
        }

        return this.versionCreate({
            wikiId: revert.wiki.id,
            wiki: revert.wiki,
            updateType: args.updateType,
            name: revert.name,
            code: revert.wiki.code,
            content: revert.content,
            status: VersionWikiStatus.UnderReview,
            thumbnailIds: revert.thumbnailIds,
            attachmentIds: revert.attachmentIds,
            versionRevertId: revert.id,
            versionRevert: revert,
            versionDraftId: null,
            approvalArgs: null,
            tagIds: revert.tags?.map(i => i.id) ?? [],
        })
    }

    async infoUpdate(args: WikiInfoUpdateInput) {
        const wiki = await DocumentWiki.createQueryBuilder()
            .where({id: args.wiki.id})
            .getOne()

        wiki.important = args.important ?? wiki.important
        if (args.categoryWikiIds) {
            wiki.categories = args.categoryWikis ?? wiki.categories
        }

        if (args.tagIds) {
            wiki.tags = args.tags ?? wiki.tags
        }

        if (args.permissions) {
            await this.permissionUpdate(args)
        }

        await wiki.save()

        return wiki
    }

    async permissionUpdate(args: WikiInfoUpdateInput) {
        const wiki = args.wiki

        await this.orgChartDocumentRepo.permissionUserUpdate(wiki.id, DocumentType.Wiki, {
            allowIds: args.permissions.allowUserIds,
            denyIds: args.permissions.denyUserIds,
        })
    }

    async manageWikiOnOff(id: string) {
        const wiki = await this.wikiRepo.getBy({id});

        if (wiki.status === WikiStatus.Draft) return wiki

        wiki.status = wiki.status === WikiStatus.Active ? WikiStatus.Inactive : WikiStatus.Active
        await wiki.save()

        return wiki
    }
}
