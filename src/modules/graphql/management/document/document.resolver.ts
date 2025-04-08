import { Args, Mutation, Query, Resolver } from '@nestjs/graphql';
import { forwardRef, Inject, SetMetadata, UseInterceptors } from "@nestjs/common";
import { DocumentService } from "./document.service";
import { DocumentFile, DocumentFolder } from "@models/entities";
import { ServiceActions, ServiceKeys, UserType } from "@core/middleware/guard/service.action";
import { FileUpload, GraphQLUpload } from "graphql-upload";
import { DocumentPermissions, RequesterId } from "@core/middleware/decorator/user.decorator";
import { DocumentElementFilter, DocumentFolderArgs, DocumentOrderBy, EditDocumentFolderArgs } from "./document.args";
import { DocumentElementResponse, DocumentFolderResponse, ObjectGenLinkWriteResponse } from "./document.response";
import { FixedDataOrgChartUserAllAndWChildInterceptor } from "@interceptors/org-chart.interceptor";
import { ErrorInterceptor } from "@interceptors/error.interceptor";

@Resolver()
export class DocumentResolver {
    constructor(
        @Inject(forwardRef(() => DocumentService))
        private readonly documentService: DocumentService,
    ) { }

    @Mutation(() => DocumentFile, { name: 'documentUploadFile' })
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    @SetMetadata(ServiceKeys.UserType, [UserType.SYSTEM_USER])
    async documentUploadFile(
        @Args({ name: 'file', type: () => GraphQLUpload }) file: FileUpload,
        @Args({ name: 'folderId', type: () => String, defaultValue: 'root' }) folderId: string,
        @Args({ name: 'override', type: () => Boolean, defaultValue: false }) override: Boolean,
        @RequesterId() requesterId: string,
    ): Promise<DocumentFile> {
        return this.documentService.documentUploadFile({file, folderId, override}, requesterId);
    }

    @Mutation(() => ObjectGenLinkWriteResponse, { name: 'documentGenLinkUpload' })
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    @SetMetadata(ServiceKeys.UserType, [UserType.SYSTEM_USER])
    async documentGenLinkUpload(
        @Args({ name: 'filename', type: () => String }) filename: string,
        @Args({ name: 'mimetype', type: () => String, nullable: true, defaultValue: '7bit' }) mimetype: string,
        @Args({ name: 'folderId', type: () => String, defaultValue: 'root' }) folderId: string,
        @Args({ name: 'override', type: () => Boolean, defaultValue: false }) override: Boolean,
        @RequesterId() requesterId: string,
    ): Promise<ObjectGenLinkWriteResponse> {
        return this.documentService.documentGenLinkUpload({filename, mimetype, folderId, override}, requesterId);
    }

    @Mutation(() => DocumentFile, { name: 'documentUploadFileSuccess' })
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    @SetMetadata(ServiceKeys.UserType, [UserType.SYSTEM_USER])
    async documentUploadFileSuccess(
        @Args({ name: 'path', type: () => String }) path: string,
        @Args({ name: 'filename', type: () => String }) filename: string,
        @Args({ name: 'mimetype', type: () => String }) mimetype: string,
        @Args({ name: 'folderId', type: () => String, defaultValue: 'root' }) folderId: string,
        @Args({ name: 'encoding', type: () => String }) encoding: string,
        @RequesterId() requesterId: string,
    ): Promise<DocumentFile> {
        return this.documentService.documentUploadFileSuccess({path, filename, mimetype, encoding, folderId}, requesterId);
    }

    @Mutation(() => DocumentFile, { name: 'documentCopyFile' })
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    @SetMetadata(ServiceKeys.UserType, [UserType.SYSTEM_USER])
    async copyFile(
        @Args({ name: 'fileId', type: () => String, nullable: false }) fileId: string,
        @Args({ name: 'folderId', type: () => String, nullable: false, defaultValue: 'root' }) folderId: string,
        @Args({ name: 'override', type: () => Boolean, defaultValue: false }) override: Boolean,
        @RequesterId() requesterId: string,
    ): Promise<DocumentFile|any> {

        return this.documentService.copyFileToFolder({fileId, folderId, override}, requesterId)
    }

    @Mutation(() => DocumentFile, { name: 'documentMoveFile' })
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    @SetMetadata(ServiceKeys.UserType, [UserType.SYSTEM_USER])
    async moveFile(
        @Args({ name: 'fileId', type: () => String, nullable: false }) fileId: string,
        @Args({ name: 'folderId', type: () => String, nullable: false, defaultValue: 'root' }) folderId: string,
        @Args({ name: 'override', type: () => Boolean, defaultValue: false }) override: Boolean,
        @RequesterId() requesterId: string,
    ): Promise<DocumentFile> {
        return this.documentService.moveFile({fileId, folderId, override}, requesterId)
    }

    @Mutation(() => DocumentFile, { name: 'documentDeleteFile' })
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    @SetMetadata(ServiceKeys.UserType, [UserType.SYSTEM_USER])
    async deleteFile(
        @Args({ name: 'fileId', type: () => String, nullable: false }) fileId: string,
        @RequesterId() requesterId: string,
    ): Promise<DocumentFile> {
        return this.documentService.deleteFile(fileId, requesterId)
    }

    @Mutation(() => DocumentFolder, { name: 'documentAddFolder' })
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    @SetMetadata(ServiceKeys.UserType, [UserType.SYSTEM_USER])
    @UseInterceptors(FixedDataOrgChartUserAllAndWChildInterceptor)
    @UseInterceptors(ErrorInterceptor)
    async documentAddFolder(
        @Args('arguments', { nullable: false }) args: DocumentFolderArgs,
        @RequesterId() requesterId: string,
    ): Promise<DocumentFolder> {
        return this.documentService.documentAddFolder(args, requesterId)
    }

    @Mutation(() => DocumentFolder, { name: 'documentEditFolder' })
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    @SetMetadata(ServiceKeys.UserType, [UserType.SYSTEM_USER])
    @UseInterceptors(FixedDataOrgChartUserAllAndWChildInterceptor)
    @UseInterceptors(ErrorInterceptor)
    async documentEditFolder(
        @Args('arguments', { nullable: false }) args: EditDocumentFolderArgs,
        @RequesterId() requesterId: string,
    ): Promise<DocumentFolder> {
        return this.documentService.documentEditFolder(args, requesterId)
    }

    @Mutation(() => DocumentFolder, { name: 'documentDeleteFolder' })
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    @SetMetadata(ServiceKeys.UserType, [UserType.SYSTEM_USER])
    async documentDeleteFolder(
        @Args({ name: 'folderId', type: () => String, nullable: false }) folderId: string,
        @RequesterId() requesterId: string,
    ): Promise<DocumentFolder> {
        return this.documentService.documentDeleteFolder(folderId, requesterId)
    }

    @Query(_return => DocumentFolderResponse, { name: "documentFolderTree" })
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    async documentFolderTree(
        @Args("parentId", { nullable: false, defaultValue: 'root' }) parentId: string,
        @DocumentPermissions() documentPermissions: any,
        @RequesterId() requesterId: string,
    ): Promise<DocumentFolderResponse> {
        return this.documentService.getFolderTree(parentId, documentPermissions, requesterId)
    }

    @Query(_return => DocumentElementResponse, { name: "documentFolderElements" })
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    async documentFolderElements(
        @Args("folderId", { nullable: false, defaultValue: 'root' }) folderId: string,
        @Args("filter", { nullable: true }) filter: DocumentElementFilter,
        @Args("order", { nullable: true }) order: DocumentOrderBy,
        @DocumentPermissions() documentPermissions: any,
        @RequesterId() requesterId: string,
    ): Promise<DocumentElementResponse> {
        // return this.documentService.getFolderElements({folderId, filter, order}, documentPermissions, requesterId)
        return this.documentService.documentSearchElements({folderId, filter, order}, documentPermissions)
    }

    @Query(_return => DocumentElementResponse, { name: "documentSearchElements" })
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    async documentSearchElements(
        @Args("folderId", { nullable: false, defaultValue: 'root' }) folderId: string,
        @Args("filter", { nullable: true }) filter: DocumentElementFilter,
        @Args("order", { nullable: true }) order: DocumentOrderBy,
        @DocumentPermissions() documentPermissions: any
    ): Promise<DocumentElementResponse> {
        return this.documentService.documentSearchElements({folderId, filter, order}, documentPermissions)
    }

    @Mutation(() => DocumentFile, { name: 'documentRenameFile' })
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    @SetMetadata(ServiceKeys.UserType, [UserType.SYSTEM_USER])
    async renameFile(
        @Args({ name: 'fileId', type: () => String, nullable: false }) fileId: string,
        @Args({ name: 'name', type: () => String, nullable: false }) name: string,
        @Args({ name: 'override', type: () => Boolean, defaultValue: false }) override: Boolean,
        @RequesterId() requesterId: string,
    ): Promise<DocumentFile> {
        return this.documentService.renameFile({fileId, name, override}, requesterId)
    }

    @Query(_return => DocumentFile, { name: "documentGetFile" })
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    async documentGetFile(
        @Args("id") id: string,
        @DocumentPermissions() documentPermissions: any
    ): Promise<DocumentFile> {
        return this.documentService.documentGetFile(id, documentPermissions)
    }

    @Query(_return => DocumentFolder, { name: "documentGetFolder" })
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    async documentGetFolder(
        @Args("id") id: string,
        @DocumentPermissions() documentPermissions: any
    ): Promise<DocumentFolder> {
        return this.documentService.documentGetFolder(id, documentPermissions)
    }
}
