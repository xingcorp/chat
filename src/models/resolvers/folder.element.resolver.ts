import { Parent, ResolveField, Resolver } from "@nestjs/graphql";
import { FolderElement } from "../../modules/graphql/management/document/document.response";
import { DocumentFolder, DocumentWiki } from "../entities";

export enum FolderElementType {
    File = "File",
    Folder = "Folder",
    Wiki = "Wiki",
}

@Resolver(_of => FolderElement)
export class FolderElementFieldResolver {
    constructor() { }

    @ResolveField('url', _return => String, { nullable: true })
    async url(
        @Parent() root: FolderElement
    ) {
        if (root && root.type === FolderElementType.File) return `${process.env.AWS_S3_DOCUMENT_OBJECT_URL || "http://localhost:5000/storage"}/${root.id}`
        return null
    }

    @ResolveField('pathName', _return => String, { nullable: true })
    async pathName(
        @Parent() root: FolderElement
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

            return root.type === FolderElementType.Folder ? pathName : `${pathName}/${root.name}`
        }

        return null
    }

    @ResolveField('wiki', _return => DocumentWiki, { nullable: true })
    async wiki(
        @Parent() root: FolderElement
    ) {
        if (root && root.type === FolderElementType.Wiki) {
            return DocumentWiki.createQueryBuilder()
                .where({
                    id: root.id
                })
                .getOne()
        }

        return null
    }
}