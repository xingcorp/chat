import { Float, Parent, ResolveField, Resolver } from "@nestjs/graphql";
import { DocumentFolder, OfficeOrgChart, OfficeUser, OrgChartDocument } from "../entities";
import { DocumentScope } from "../entities/document.folder";
import { DocumentType } from "../entities/org.chart.document";
import { In, IsNull, Not } from "typeorm";
import { InjectRepository } from "@nestjs/typeorm";
import { VersionWikiRepo, ViewerRepo, WikiRepo } from "@models/repositories";
import { RequestContext } from "@common/context/request.context";

@Resolver(_of => DocumentFolder)
export class DocumentFolderFieldResolver {
    constructor(
        @InjectRepository(WikiRepo)
        private wikiRepo: WikiRepo,
        @InjectRepository(VersionWikiRepo)
        private versionWikiRepo: VersionWikiRepo,
        @InjectRepository(ViewerRepo)
        private readonly viewerRepo: ViewerRepo
    ) { }

    @ResolveField('pathName', _return => String, { nullable: true })
    async pathName(
        @Parent() root: DocumentFolder
    ) {
        if (root.path) {
            var pathName = ""
            const folderIds = root.path.split("/")

            for (const folderId of folderIds) {
                const folder = folderId ? await DocumentFolder.findOne({ where: { id: folderId } }) : null
                if (folder) {
                    pathName += `/${folder.name}`
                }
            }

            return pathName
        }

        return null
    }

    @ResolveField('parentFolder', _return => DocumentFolder, { nullable: true })
    async parentFolder(
        @Parent() root: DocumentFolder
    ) {
        if (root.parentId !== 'root') {
            return DocumentFolder.findOne({
                where: {
                    id: root.parentId
                }
            })
        }

        return null
    }

    @ResolveField('departments', _return => [OfficeOrgChart], { nullable: true })
    async departments(
        @Parent() root: DocumentFolder
    ) {
        if (root.scope === DocumentScope.Private) {
            const relations = await OrgChartDocument.find({
                where: {
                    documentId: root.id,
                    type: DocumentType.Folder,
                    departmentId: Not(IsNull())
                }
            })

            return OfficeOrgChart.find({
                where: {
                    id: In(relations.map(r => r.departmentId))
                }
            })
        }

        return null
    }

    @ResolveField('users', _return => [OfficeUser], { nullable: true })
    async users(
        @Parent() root: DocumentFolder
    ) {
        if (root.scope === DocumentScope.Private) {
            const relations = await OrgChartDocument.find({
                where: {
                    documentId: root.id,
                    type: DocumentType.Folder,
                    userId: Not(IsNull())
                }
            })

            return OfficeUser.find({
                where: {
                    id: In(relations.map(r => r.userId))
                }
            })
        }

        return null
    }

    @ResolveField('unreadWikiCount', _return => Float, { nullable: true })
    async unreadWikiCount(
        @Parent() root: DocumentFolder
    ) {
        if (RequestContext.isSysUser()) return null
        const wikis = await this.wikiRepo.getAllOfFolderByFolderId(root.id)
        const versions = await this.versionWikiRepo.getAllLatestVersionOfListWikis(wikis.map(i => i.id) ?? [])

        return this.viewerRepo.countUnreadVersionWikiInListOfUser(versions.map(i => i.id) ?? [], await RequestContext.currentId())
    }
}