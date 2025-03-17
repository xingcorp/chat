import { Parent, ResolveField, Resolver } from "@nestjs/graphql";
import { CategoryWiki, DocumentFolder, DocumentWiki, OfficeUser, VersionWiki } from "@models/entities";
import { RequestContext } from "@common/context/request.context";
import { VersionWikiStatus } from "@enum/wiki/wiki.enum";
import { InjectRepository } from "@nestjs/typeorm";
import { VersionWikiRepo, WikiRepo } from "@models/repositories";
import { ViewerRepo } from "@repositories/viewer/viewer.repo";
import { DocumentHelpers } from "@helpers/logics/documents/document.helpers";
import { UserDocumentPermissionResponse } from "@args/document/response.document";

@Resolver(_of => DocumentWiki)
export class WikiResolver {
    constructor(
        @InjectRepository(WikiRepo)
        private wikiRepo: WikiRepo,
        @InjectRepository(VersionWikiRepo)
        private versionWikiRepo: VersionWikiRepo,
        @InjectRepository(ViewerRepo)
        private readonly viewerRepo: ViewerRepo
    ) {
    }

    @ResolveField('versions', _return => [VersionWiki], {nullable: true})
    async versions(
        @Parent() root: DocumentWiki
    ) {
        const versions = await VersionWiki.createQueryBuilder()
            .where({
                wiki: {
                    id: root.id
                }
            })
            .getMany()

        if (RequestContext.isNormalUser()) {
            return versions.filter(i => i.isPublic)
        }

        return versions
    }

    @ResolveField('approvalVersion', _return => VersionWiki, {nullable: true})
    async approvalVersion(
        @Parent() root: DocumentWiki
    ) {
        const _root = await this.wikiRepo.getBy({id: root.id}, ['versions'])

        return _root.versions.find(i => [VersionWikiStatus.UnderReview, VersionWikiStatus.Pending].includes(i.status))
    }

    @ResolveField('latestVersion', _return => VersionWiki, {nullable: true})
    async latestVersion(
        @Parent() root: DocumentWiki
    ) {
        return VersionWiki.createQueryBuilder()
            .where({
                wiki: {
                    id: root.id
                },
                isLatestVersion: true
            })
            .getOne()
    }

    @ResolveField('folder', _return => DocumentFolder, {nullable: true})
    async folder(
        @Parent() root: DocumentWiki
    ) {
        const _root = await this.wikiRepo.getBy({id: root.id}, ['folder'])

        if (!_root) return null

        return _root?.folder
    }

    @ResolveField('userCreator', _return => OfficeUser, {nullable: true})
    async userCreator(
        @Parent() root: DocumentWiki
    ) {
        const _root = await this.wikiRepo.getBy({id: root.id}, ['userCreator'])

        return _root.userCreator
    }

    @ResolveField('categories', _return => [CategoryWiki], {nullable: true})
    async categories(
        @Parent() root: DocumentWiki
    ) {
        const _root = await this.wikiRepo.getBy({id: root.id}, ['categories'])

        return _root.categories
    }

    @ResolveField('userPermissions', _return => UserDocumentPermissionResponse, {nullable: true})
    async userPermissions(
        @Parent() root: DocumentWiki
    ) {
        return DocumentHelpers.allUserPermissionOfDocumentFollowDepartment(await DocumentHelpers.allUserIdPermissionOfWiki(root.id))
    }

    @ResolveField('isRead', _return => Boolean, {nullable: true})
    async isRead(
        @Parent() root: DocumentWiki
    ) {
        if (!RequestContext.isNormalUser()) return true

        const version = await this.versionWikiRepo.getLatestVersionOfWiki(root.id)

        return this.viewerRepo.isRequestReadThisVersionWiki(version.id, await RequestContext.currentId())
    }
}