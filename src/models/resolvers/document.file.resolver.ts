import { Parent, ResolveField, Resolver } from "@nestjs/graphql";
import { DocumentFile, DocumentFolder } from "../entities";

@Resolver(_of => DocumentFile)
export class DocumentFileFieldResolver {
    constructor() { }

    @ResolveField('pathName', _return => String, { nullable: true })
    async pathName(
        @Parent() root: DocumentFile
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

            return `${pathName}/${root.name}`
        }

        return null
    }

    @ResolveField('folder', _return => DocumentFolder, { nullable: true })
    async folder(
        @Parent() root: DocumentFile
    ) {
        if (root.folderId !== 'root') {
            return DocumentFolder.findOne({
                where: { id: root.folderId }
            })
        }

        return null
    }

    @ResolveField('url', _return => String, { nullable: true })
    async url(
        @Parent() root: DocumentFile
    ) {
        if (root && root.id) return `${process.env.AWS_S3_DOCUMENT_OBJECT_URL || "http://localhost:5000/storage"}/${root.id}`
        return null
    }
}