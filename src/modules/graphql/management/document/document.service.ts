import { Inject, Injectable } from '@nestjs/common';
import { DocumentStoreInterface, STORE_SERVICE } from "./store/document-store-interface.interface";
import { FileUpload } from "graphql-upload";
import {
    DocumentFile,
    DocumentFolder,
    OfficeOrgChart, OfficeUser,
    OrgChartDocument, UserDepartment, VersionWiki
} from "@models/entities";
import { OfficeError } from "@common/office.error";
import { FileMetadata } from "@google-cloud/storage";
import { buildExceptionResponse } from "@core/common/error.builder";
import { pluck } from "@utils/object.utils";
import { getNameAndExtFile, isVideoFile } from "@utils/file.utils";
import { RandomHelper } from "@common/random";
import { DocumentScope } from "@models/entities/document.folder";
import { Brackets, Connection, ILike, In, IsNull, Not, Repository } from "typeorm";
import { DocumentType, ObjectEffect } from "@models/entities/org.chart.document";
import {
    DocumentElementFilter,
    DocumentFolderArgs,
    DocumentOrderBy,
    EditDocumentFolderArgs,
    ViewDocumentArgs
} from "./document.args";
import { BaseError, HttpError } from "@core/core.error";
import { UserType } from "@core/middleware/guard/service.action";
import { InjectConnection, InjectRepository } from "@nestjs/typeorm";
import { IAMGraphQlClient } from "@core/iam/iam.client";
import { RedisService } from "@core/common/redis.service";
import { OfficeSysUser } from "@models/entities/system.user";
import { OfficeOrgChartRepo } from "@models/repositories/office-org-chart.repo";
import { OfficeOrgChartDocumentRepo } from "@models/repositories/office-org-chart-document.repo";
import { FolderElementType } from "@models/resolvers/folder.element.resolver";
import { RequestContext } from "@common/context/request.context";
import { arrayConvertToDistinctAndNotNull } from "@utils/array.utils";
import { UserDepartmentRepo, VersionWikiRepo, WikiRepo } from "@models/repositories";
import { DocumentHelpers } from "@helpers/logics/documents/document.helpers";

const DOCUMENT_BUCKET_CORS_ORIGIN = 'DOCUMENT_BUCKET_CORS_ORIGIN'

@Injectable()
export class DocumentService {
    constructor(
        @Inject('DocumentStoreService')
        private readonly documentStoreService: DocumentStoreInterface,
        @InjectConnection()
        private readonly connection: Connection,
        private readonly iamClient: IAMGraphQlClient,
        @InjectRepository(DocumentFolder)
        private documentFolderRepository: Repository<DocumentFolder>,
        @InjectRepository(DocumentFile)
        private documentFileRepository: Repository<DocumentFile>,
        private readonly cacheService: RedisService,
        private orgChartRepository: OfficeOrgChartRepo,
        private orgChartDocumentRepo: OfficeOrgChartDocumentRepo,
        private readonly wikiRepo: WikiRepo,
        private readonly versionWikiRepo: VersionWikiRepo,
        private readonly userDepartmentRepo: UserDepartmentRepo,
    ) {
    }

    async getFolder(id: string, error?: BaseError) {
        const folder = await this.documentFolderRepository.findOne({ where: { id } })
        if (!folder) throw error ?? OfficeError.DocumentFolderNotFound

        return folder
    }

    async checkFileName(filename: string, folderId?: string, isThrow: boolean = true) {
        const checkName = await this.documentFileRepository.findOne({
            where: {
                name: filename,
                folderId: folderId ?? 'root'
            }
        })
        if (checkName && isThrow) throw OfficeError.DocumentFileIsExisted

        return checkName
    }

    async checkFolderName(name: string, parentId?: string, isThrow: boolean = true) {
        const checkName = await this.documentFolderRepository.findOne({
            where: {
                name,
                parentId: parentId ?? 'root'
            }
        })
        if (checkName && isThrow) throw OfficeError.DocumentFolderIsExisted

        return checkName
    }

    async getFile(id: string) {
        const file = await this.documentFileRepository.findOne({ where: { id } })
        if (!file) throw OfficeError.DocumentFileNotFound

        return file
    }

    private async checkPermission(id: string, token: any) {
        const checkPermission = await this.checkDocumentPermission(id, `Bearer ${token}`)
        if (checkPermission === false) throw OfficeError.DocumentFilePermissionDenied
    }

    public async checkDocumentPermission(
        documentId: string,
        token: string
    ): Promise<Boolean> {
        const { data, error } = await this.iamClient.getPermission(token, [])
        if (error) {
            console.log("[checkDocumentPermission] ERR: ", error.message)
            // return false
            throw HttpError.Unauthorized
        }

        const userType = data.userInfo.user.type
        if (userType === UserType.NORMAL_USER) {
            const officeUser = await OfficeUser.findOne({
                where: { iamUserId: data.userInfo.userId }
            })

            if (!officeUser) {
                console.log("[checkDocumentPermission] ERR: officeUser not found - ", data.userInfo.userId)
                return false
            }

            const userDepartments = await UserDepartment.find({
                where: {
                    userId: officeUser.id
                }
            })
            const allowFolders = await OrgChartDocument.find({
                where: [
                    {
                        departmentId: In(userDepartments.map(ud => ud.departmentId)),
                        type: DocumentType.Folder
                    },
                    {
                        userId: officeUser.id,
                        type: DocumentType.Folder
                    }
                ]
            })

            const whereOptions: any[] = [{
                scope: DocumentScope.Public
            }]
            for (const iterator of allowFolders) {
                whereOptions.push({
                    path: ILike(`%${iterator.documentId}%`)
                })
            }

            const folders = await this.documentFolderRepository.find({
                where: whereOptions
            })
            const files = await this.documentFileRepository.find({
                where: folders.map(folder => {
                    return {
                        path: ILike(`%${folder.id}%`)
                    }
                })
            })

            const fileIds = files.map(f => f.id)
            if (!fileIds.includes(documentId)) return false
        }

        return true
    }

    public async documentUploadFile(args: {
        file: FileUpload;
        override: Boolean;
        folderId: string
    }, requesterId: string): Promise<DocumentFile> {
        const { file, folderId, override } = args;
        let folder = null
        if (folderId !== 'root') {
            folder = await this.getFolder(folderId)
        }

        if (override === false) {
            await this.checkFileName(file.filename, folder?.id)
        }

        try {
            return this.storeAndRemoveDuplicateDoc(file, folder, requesterId)

        } catch (error) {
            console.log('Upload document has failed: ', error)
            throw buildExceptionResponse(error)
        }
    }

    async documentGenLinkUpload(args: {
        filename: string;
        mimetype: string;
        override: Boolean;
        folderId: string
    }, requesterId: string) {
        const { filename, mimetype, folderId, override } = args;
        let folder = null
        if (folderId !== 'root') {
            folder = await this.getFolder(folderId)
        }

        if (override === false) {
            await this.checkFileName(filename, folder?.id)
        }

        const folderPath = await this.getFolderPath(folder)

        const fullFilename = `${folderPath}/${filename}`

        try {
            return {
                uploadUrl: await this.documentStoreService.genSignedUrlWriteObject(fullFilename, mimetype),
                path: fullFilename,
            }

        } catch (error) {
            console.log('Gen link upload document has failed: ', error)
            throw buildExceptionResponse(error)
        }
    }

    async documentUploadFileSuccess(params: {
        path: string;
        filename: string;
        mimetype: string;
        encoding: string,
        folderId: string
    }, requesterId: string) {
        const metadata: FileMetadata = await this.documentStoreService.getMetadataObj(params.path)
        let folder = null
        if (params.folderId !== 'root') {
            folder = await this.getFolder(params.folderId)
        }

        return this.storeAndRemoveDuplicateFromDB({
            name: params.filename,
            mimetype: params.mimetype,
            encoding: params.encoding,
            etag: metadata.etag as string,
            key: params.path,
            bucket: metadata.bucket,
            location: metadata.selfLink,
            size: metadata.size as string,
            folderId: folder?.id,
            createdBy: requesterId,
            updatedBy: requesterId
        } as DocumentFile
            , folder)
    }

    async getFolderPath(folder: DocumentFolder) {
        let folderPath: string = ""
        if (folder !== null) {
            const folderIds = folder.path.split("/")
            for (const folderId of folderIds) {
                const folder = folderId ? await this.documentFolderRepository.findOne({ where: { id: folderId } }) : null
                if (folder) {
                    if (folderPath) {
                        folderPath += `/${folder.name}`
                    } else {
                        folderPath = folder.name
                    }
                }
            }
        }

        return folderPath
    }

    async storeAndRemoveDuplicateFromDB(documentFileData: DocumentFile, folder): Promise<DocumentFile> {
        const result = this.documentFileRepository.create(documentFileData)

        await this.documentFileRepository.delete({
            name: documentFileData.name,
            folderId: folder ? folder.id : 'root'
        })

        return result.save()
    }

    public async copyFileToFolder(args: { override: Boolean; folderId: string; fileId: string }, requesterId: string) {
        const existedFile = await this.getFile(args.fileId)
        const originFile = structuredClone(existedFile)

        // check folder exist
        let folder = null
        if (args.folderId !== 'root') {
            folder = await this.getFolder(args.folderId)
        }

        if (existedFile.folderId === args.folderId) {
            // clone to same folder
            existedFile.name = await this.getCopyFileName(existedFile.name, args.folderId)
        } else {

            const checkName = await this.checkFileName(existedFile.name, folder?.id, false)

            if (checkName && !args.override) {
                existedFile.name = await this.getCopyFileName(existedFile.name, args.folderId)
            }
        }

        const metadata = await this.storeCopyDoc(originFile, existedFile, folder)

        return this.storeAndRemoveDuplicateFromDB({
            name: existedFile.name,
            mimetype: existedFile.mimetype,
            encoding: existedFile.encoding,
            etag: metadata.etag as string,
            key: existedFile.key,
            bucket: metadata.bucket,
            location: metadata.selfLink,
            size: metadata.size as string,
            folderId: folder?.id,
            createdBy: requesterId,
            updatedBy: requesterId,
        } as DocumentFile
            , originFile)
    }

    async getCopyFileName(oriName: string, folderId: string): Promise<string> {
        const names = pluck(await this.documentFileRepository.find({
            where: { folderId }
        }), 'name')

        const [name, ext] = getNameAndExtFile(oriName)

        let i = 1;
        let copyName = ''

        while (true) {
            copyName = `${name} (${i++}).${ext}`
            if (!names.includes(copyName)) return copyName
        }
    }

    private async storeAndRemoveDuplicateDoc(file: FileUpload, folder: any, requesterId: string) {
        const { filename, mimetype, encoding } = file

        const folderPath = await this.getFolderPath(folder)

        const fullFilename = `${folderPath}/${filename}`

        await this.documentStoreService.uploadFile(file, fullFilename)

        const metadata: FileMetadata = await this.documentStoreService.getMetadataObj(fullFilename)

        // if (isVideoFile(filename)) {
        //     await this.documentStoreService.convertMedia(metadata.bucket, fullFilename)
        // }

        return this.storeAndRemoveDuplicateFromDB({
            name: filename,
            mimetype: mimetype,
            encoding: encoding,
            etag: metadata.etag as string,
            key: fullFilename,
            bucket: metadata.bucket,
            location: metadata.selfLink,
            size: metadata.size as string,
            folderId: folder?.id,
            createdBy: requesterId,
            updatedBy: requesterId
        } as DocumentFile
            , folder)
    }

    private async storeCopyDoc(originFile: DocumentFile, cloneFile: DocumentFile, folder: any) {
        const folderPath = await this.getFolderPath(folder)

        const fullFilename = `${folderPath}/${cloneFile.name}`

        cloneFile.key = fullFilename

        await this.documentStoreService.copyFile(originFile, cloneFile)

        return this.documentStoreService.getMetadataObj(fullFilename)
    }

    async moveFile(args: { override: Boolean; folderId: string; fileId: string }, requesterId: string) {
        const { fileId, folderId, override } = args

        const existedFile = await this.getFile(fileId)

        if (existedFile.folderId !== folderId) {
            let folder = null
            if (folderId !== 'root') {
                folder = await this.getFolder(folderId)
            }

            if (override === false) {
                await this.checkFileName(existedFile.name, folder?.id)
            }

            try {
                const cloneFile = structuredClone(existedFile)

                const metadata = await this.storeCopyDoc(existedFile, cloneFile, folder)

                const result = this.documentFileRepository.create({
                    name: cloneFile.name,
                    mimetype: cloneFile.mimetype,
                    encoding: cloneFile.encoding,
                    key: cloneFile.key,
                    etag: metadata.etag as string,
                    bucket: metadata.bucket,
                    location: metadata.selfLink,
                    size: metadata.size as string,
                    folderId: folder?.id,
                    createdBy: requesterId,
                    updatedBy: requesterId,
                })

                await this.removeFileFromStoreAndDB(existedFile)

                return result.save()
            } catch (error) {
                console.log('[MOVE] Upload document has failed: ', error)
                throw buildExceptionResponse(error)
            }
        }

        return existedFile
    }

    async deleteFile(fileId: string, requesterId: string) {
        const file = await this.getFile(fileId)

        await this.removeFileFromStoreAndDB(file)

        return file
    }

    private async removeFileFromStoreAndDB(file: DocumentFile) {
        await this.documentStoreService.deleteFile(file)

        return file.remove()
    }

    async documentAddFolder(args: DocumentFolderArgs, requesterId: string) {
        const folder = this.documentFolderRepository.create({
            id: RandomHelper.generateUUID(),
            name: args.name,
            note: args.note,
            scope: args.scope,
            createdBy: requesterId,
            updatedBy: requesterId
        })

        if (args.parentId) {
            await this.getFolder(args.parentId)
            folder.parentId = args.parentId
        }

        await this.checkFolderName(args.name, args.parentId)

        await this.createOrgChartDocument(folder, args)

        return folder.save()
    }

    private async createOrgChartDocument(folder: DocumentFolder, args: DocumentFolderArgs) {
        const orgChartDocuments: OrgChartDocument[] = []
        if (folder.scope === DocumentScope.Private) {
            if (args.departmentIds && args.departmentIds.length) {
                orgChartDocuments.push(...(await this.createOrgChartDocumentDepartment(folder, args)))
            }

            if (args.userIds && args.userIds.length) {
                orgChartDocuments.push(...(await this.createOrgChartDocumentUser(folder, args)))
            }
        }

        if (orgChartDocuments.length > 0) await OrgChartDocument.save(orgChartDocuments)
    }

    async documentEditFolder(args: EditDocumentFolderArgs, requesterId: string) {
        const existedFolder = await this.getFolder(args.id)

        // if (args.name) existedFolder.name = args.name
        if (args.note !== undefined) existedFolder.note = args.note
        if (args.parentId && args.parentId !== existedFolder.parentId) {
            //check valid parentId
            const childFolders = await this.documentFolderRepository.find({
                where: {
                    path: ILike(`%${existedFolder.id}%`)
                }
            })
            const childIds = childFolders.map(f => f.id)
            if (childIds.includes(args.parentId)) {
                throw OfficeError.DocumentFolderParentInvalid
            }

            const oldPath = existedFolder.path
            var path = existedFolder.path
            if (args.parentId === 'root') {
                path = `/${existedFolder.id}`
            } else {
                const parent = await this.getFolder(args.parentId, OfficeError.DocumentFolderParentNotFound)
                path = `${parent.path}/${existedFolder.id}`
            }

            existedFolder.parentId = args.parentId
            existedFolder.path = path

            // update children
            await this.updateChildOfDocumentEdit(childFolders, existedFolder, oldPath)
        }

        if (args.name && existedFolder.name !== args.name) {
            await this.checkFolderName(args.name, existedFolder.parentId)
            existedFolder.name = args.name
        }

        if (args.scope) existedFolder.scope = args.scope

        await this.removeOrgChartDocumentOfOldFolder(existedFolder, args)

        existedFolder.updatedBy = requesterId
        return existedFolder.save()
    }

    private async updateChildOfDocumentEdit(childFolders: DocumentFolder[], existedFolder: DocumentFolder, oldPath: string) {
        for (const child of childFolders) {
            child.path = child.path.replace(oldPath, existedFolder.path)
        }
        const childFiles = await this.documentFileRepository.find({
            where: {
                path: ILike(`%${existedFolder.id}%`)
            }
        })
        for (const child of childFiles) {
            child.path = child.path.replace(oldPath, existedFolder.path)
        }
        await this.documentFolderRepository.save(childFolders)
        return this.documentFileRepository.save(childFiles)
    }

    private async removeOrgChartDocumentOfOldFolder(existedFolder: DocumentFolder, args: EditDocumentFolderArgs) {
        let deletedOrgChartDocuments: OrgChartDocument[] = []
        const orgChartDocuments: OrgChartDocument[] = []
        if (existedFolder.scope === DocumentScope.Private) {
            let updatePermission = false
            if (args.departmentIds && args.departmentIds.length) {
                orgChartDocuments.push(...(await this.createOrgChartDocumentDepartment(existedFolder, args)))
                updatePermission = true
            }

            if (args.userIds && args.userIds.length) {
                orgChartDocuments.push(...(await this.createOrgChartDocumentUser(existedFolder, args)))
                updatePermission = true
            }

            if (updatePermission) {
                deletedOrgChartDocuments = await OrgChartDocument.find({
                    where: {
                        documentId: existedFolder.id,
                        type: DocumentType.Folder
                    }
                })
            }
        } else if (existedFolder.scope === DocumentScope.Public) {
            deletedOrgChartDocuments = await OrgChartDocument.find({
                where: {
                    documentId: existedFolder.id,
                    type: DocumentType.Folder
                }
            })
        }

        if (deletedOrgChartDocuments.length > 0) await OrgChartDocument.remove(deletedOrgChartDocuments)
        if (orgChartDocuments.length > 0) await OrgChartDocument.save(orgChartDocuments)
    }

    async documentDeleteFolder(folderId: string, requesterId: string) {
        const existedFolder = await this.getFolder(folderId)

        // remove from store
        await this.deleteFolderFromStore(existedFolder)

        // remove from DB
        await this.deleteFolderByIdFromDB(existedFolder.id)

        return existedFolder
    }

    private async deleteFolderFromStore(folder: DocumentFolder) {
        let pathName = ""
        const folderIds = folder.path.split("/")

        for (const folderId of folderIds) {
            const folder = folderId ? await this.getFolder(folderId, OfficeError.DocumentFolderParentNotFound) : null
            if (folder) {
                pathName += `${folder.name}/`
            }
        }

        return this.documentStoreService.deleteFolder(pathName)
    }

    private async deleteFolderByIdFromDB(id: string) {
        await this.documentFileRepository.delete({
            path: ILike(`%${id}%`)
        })

        const documents = await this.documentFolderRepository.find({
            where: { path: ILike(`%${id}%`) }
        })

        await this.removeWikiOfDocuments(documents)

        return this.documentFolderRepository.softRemove(documents)
    }

    async getAllSysFolderIds(ids: string[]) {
        const oogIds = await this.orgChartRepository.getIdsCurrentAndLineParentAndAllChild(ids)
        return this.orgChartDocumentRepo.getAllDocIdsByDepartmentIds(oogIds)
    }

    async getAllSysFileIdsByFolderIds(ids: string[]) {
        const files = await DocumentFile.find({
            where: {
                folderId: In(ids)
            }
        })

        return files.map(i => i.id)
    }

    async getFolderTree(parentId: string, documentPermissions: any, requesterId: string) {
        let res
        if (documentPermissions.userType === UserType.SYSTEM_USER) {
            const admin = await OfficeSysUser.findOne({
                where: {
                    id: requesterId,
                }
            })

            if (!admin.orgChartIds) {
                // Full Admin
                res = await this.documentFolderRepository.findAndCount({
                    where: {
                        parentId: parentId,
                    }
                })
            } else {
                const ids = await this.getAllSysFolderIds(admin.orgChartIds)

                res = await this.documentFolderRepository.findAndCount({
                    where: [
                        {
                            parentId: parentId,
                            id: In(ids || [])
                        },
                        {
                            parentId: parentId,
                            createdBy: RequestContext.currentRequestId()
                        }
                    ]
                })
            }
        } else {
            res = await this.getAndCountFolderTreeOfUser(parentId, documentPermissions)
        }

        const [list, count] = res

        return {
            total: count,
            count: list.length,
            folders: list
        }
    }

    async getFolderElements(args: {
        filter: DocumentElementFilter;
        folderId: string;
        order: DocumentOrderBy
    }, documentPermissions: any, requesterId: string) {
        const { folderId, filter, order } = args

        const documentIds = await this.getAllDocumentAllowOfRequester(documentPermissions)

        const [list, count] = await this.listDocumentElementRawQuery(folderId, filter, order, documentIds)

        return {
            total: count,
            count: list.length,
            elements: list
        }
    }

    /*legacy*/
    private async listDocumentElementRawQuery(folderId: string, filter: DocumentElementFilter, order: DocumentOrderBy, documentIds: any) {
        let query = `
            select odf.id,
                   odf."name",
                   'File'          as "type",
                   odf.mimetype,
                   odf."size",
                   odf."updatedAt" as "modifiedAt",
                   odf."path"      as "path",
                   null            as "version",
                   null            as "status",
                   null            as "approvalVersion"
            from office."office-document-files" odf
            where odf."deletedAt" is null
              and odf."folderId" = '${folderId}'
            union
            select ofo.id,
                   ofo."name",
                   'Folder'        as "type",
                   null            as "mimetype",
                   null            as "size",
                   ofo."updatedAt" as "modifiedAt",
                   ofo."path"      as "path",
                   null            as "version",
                   null            as "status",
                   null            as "approvalVersion"
            from office."office-document-folders" ofo
            where ofo."deletedAt" is null
              and ofo."parentId" = '${folderId}'
            union
            select wiki.id,
                   wiki."name",
                   'Wiki'                as "type",
                   null                  as "mimetype",
                   null                  as "size",
                   wiki."updatedAt"      as "modifiedAt",
                   null                  as "path",
                   "latestVer".version   AS "version",
                   coalesce("approvalVer".status, "latestVer".status, "lastNotApproval".status, "wiki".status)
                                         AS "status",
                   "approvalVer".version as "approvalVersion"
            from "office"."office-document-wikis" wiki
                     LEFT JOIN office."office-document-wiki-versions" "latestVer"
                               ON "wiki"."id" = "latestVer"."wikiId" and
                                  "latestVer"."isLatestVersion" is true and "latestVer"."deletedAt" is null
                     LEFT JOIN office."office-document-wiki-versions" "approvalVer"
                               ON "wiki"."id" = "approvalVer"."wikiId" and
                                  "approvalVer"."status" in ('UnderReview', 'Pending') and
                                  "approvalVer"."deletedAt" is null
                     left join lateral (
                select *
                from office."office-document-wiki-versions" e
                where e."wikiId" = "wiki"."id"
                  and e."status" not in ('Draft', 'Approved')
                  and e."deletedAt" is null
                order by e."createdAt" desc
                limit 1
                ) "lastNotApproval" on true
            WHERE wiki."folderId" = '${folderId}'
        `

        //skip
        let offset = 0
        if (filter && filter.page) {
            let skip = !filter.size ? 0 : filter.size * (filter.page - 1)
            skip = skip < 0 ? 0 : skip
            offset = skip
        }

        //take
        let limit = 20
        if (filter && filter.size) {
            limit = filter.size
        }

        let whereOptions = ""
        if (filter && filter.keyword) {
            whereOptions += `where unaccent(regexp_replace("name", '[^\\w]+','','g')) ilike unaccent('%${filter.keyword}%')`
        }

        if (documentIds) {
            if (whereOptions) {
                whereOptions += ' and "id" in ('
            } else {
                whereOptions = 'where "id" in ('
            }
            for (let i = 0; i < documentIds.length; i++) {
                const element = documentIds[i];
                if (i === 0) {
                    whereOptions += `'${element}'`
                } else {
                    whereOptions += `,'${element}'`
                }
            }
            whereOptions += ')'
        }

        let orderQuery = ""
        if (order.field) {
            orderQuery += `order by "${order.field}" ${order.order}`
        }

        const countQuery = `select count(*)
                            from (select * from (${query}) tbl ${whereOptions}) as c`
        const pagingQuery = `select *
                             from (${query}) tbl ${whereOptions} ${orderQuery}
                             limit ${limit} offset ${offset}`
        // console.log("QUERY: ", pagingQuery)
        // console.log("data: ", await this.connection.query(pagingQuery))
        return [
            await this.connection.query(pagingQuery),
            Number((await this.connection.query(countQuery))[0].count)
        ]
    }

    async documentSearchElements(args: {
        filter: DocumentElementFilter;
        folderId: string;
        order: DocumentOrderBy
    }, documentPermissions: any) {
        const { folderId, filter, order } = args
        const userPermissions = await DocumentHelpers.allUserPermissionOfDocumentFollowDepartment(
            await DocumentHelpers.allUserIdPermissionOfDocument(folderId)
        )

        if (filter && (JSON.parse(JSON.stringify(filter))).hasOwnProperty('keyword') && filter.keyword === null && folderId === 'root') {
            return {
                total: 0,
                count: 0,
                elements: [],
                userPermissions
            }
        }

        const documentIds = await this.getAllDocumentAllowOfRequester(documentPermissions)

        const folder = folderId !== 'root' ? await this.documentFolderRepository.findOne({
            where: {
                id: folderId
            }
        }) : null
        const [list, count] = await this.listSearchElementRawQuery(folder, filter, order, documentIds)

        return {
            total: count,
            count: list.length,
            elements: list,
            userPermissions
        }
    }

    private async listSearchElementRawQuery(folder: DocumentFolder, filter: DocumentElementFilter, order: DocumentOrderBy, documentIds: any) {
        const folderPath = folder ? folder.path : "/"

        filter.size = filter.size ? filter.size : 20
        filter.page = filter.page ? (filter.page - 1) : 0

        let query1 = DocumentFile.createQueryBuilder('dfi')
            .select([
                `dfi.id as id`,
                `dfi.name as name`,
                `'${FolderElementType.File}' as "type"`,
                `dfi.mimetype as mimetype`,
                `dfi.size as size`,
                `dfi."updatedAt" as "modifiedAt"`,
                `dfi."path" as "path"`,
                `null            as "version"`,
                `null            as "status"`,
                `null            as "approvalVersion"`,
                `null            as "folderId"`,
                `'Active'            as "activeStatus"`,
            ])
            .getQuery()

        let query2 = this.documentFolderRepository.createQueryBuilder('dfl')
            .select([
                'dfl.id as id',
                'dfl.name as name',
                `'${FolderElementType.Folder}' as "type"`,
                'null as "mimetype"',
                'null as "size"',
                `dfl."updatedAt" as "modifiedAt"`,
                `dfl."path" as "path"`,
                `null            as "version"`,
                `null            as "status"`,
                `null            as "approvalVersion"`,
                `null            as "folderId"`,
                `'Active'            as "activeStatus"`,
            ])
            .getQuery()

        let query3 = this.wikiRepo.createQueryBuilder('wiki')
            .leftJoinAndSelect('wiki.folder', 'folder')
            .leftJoinAndMapOne('wiki.latestVer', VersionWiki, 'latestVer', 'wiki.id::text = "latestVer"."wikiId"::text ' +
                'and "latestVer"."isLatestVersion" is true and "latestVer"."deletedAt" is null')
            .leftJoinAndMapOne('wiki.approvalVer', VersionWiki, 'approvalVer', '"wiki"."id"::text = "approvalVer"."wikiId"::text ' +
                'and "approvalVer"."status" in (\'UnderReview\', \'Pending\') ' +
                'and "approvalVer"."deletedAt" is null'
            )
            .leftJoin(
                '(SELECT 1)',
                "dummy",
                'TRUE LEFT JOIN LATERAL (select * from office."office-document-wiki-versions" e ' +
                'where e."wikiId"::text = "wiki"."id"::text and e."status" not in (\'Draft\', \'Approved\') ' +
                'and e."deletedAt" is null order by e."createdAt" desc limit 1) "lastNotApproval" on true'
            )
            .select([
                'wiki.id as id',
                'wiki.name as name',
                `'${FolderElementType.Wiki}' as "type"`,
                'null as "mimetype"',
                'null as "size"',
                `wiki."updatedAt" as "modifiedAt"`,
                `null as "path"`,
                `"latestVer".version   AS "version"`,
                `coalesce("approvalVer".status, "latestVer".status, "lastNotApproval".status, "wiki".status) AS "status"`,
                `"approvalVer".version as "approvalVersion"`,
                `"folder".id::text as "folderId"`,
                `"wiki".status            as "activeStatus"`,
            ])
            .getQuery()

        let query = this.connection
            .createQueryBuilder()
            .from(`(${query1} UNION ${query2} UNION ${query3})`, 'qb')
            .where(new Brackets(db => {
                db.where(`unaccent(LOWER(qb.path)) ILIKE unaccent(LOWER(:path))`, { path: `%${folderPath.trim()}%` })
                    .orWhere(`qb."folderId" = :folderId`, { folderId: folder?.id })
            }))

        if (folder) query.andWhere({ id: Not(folder?.id) })

        if (RequestContext.isNormalUser()) {
            const denyIds = await OrgChartDocument.find({
                where: {
                    userId: RequestContext.currentId(),
                    type: DocumentType.Wiki,
                    effect: ObjectEffect.Deny
                }
            })

            query
                .andWhere(`qb."activeStatus"::text <> 'Inactive'`)
                .andWhere({
                    id: Not(In(denyIds.map(i => i?.documentId) ?? []))
                })
        }

        if (filter && filter.keyword) {
            query = query
                .andWhere(`unaccent(LOWER(qb.name)) ILIKE unaccent(LOWER(:name))`, { name: `%${filter.keyword.trim()}%` })
        }

        if (documentIds) {
            query = query.andWhere(`qb.id in (:...ids)`, { ids: documentIds })
        }

        if (order.field) {
            query = query.orderBy(`qb.${order.field}`, order.order)
        }

        const [rawQuery, params] = query.getQueryAndParameters()

        const countQuery = `select count(*)
                            from (${rawQuery}) as c`
        const pagingQuery = query
            .take(filter.size)
            .skip(filter.page * filter.size)
            .getQueryAndParameters()[0]

        return [
            await this.connection.query(pagingQuery, params),
            Number((await this.connection.query(countQuery, params))[0].count)
        ]
    }

    async getDocumentPreviewUrl(id: string, query: ViewDocumentArgs) {
        const document = await this.getFile(id)

        await this.checkPermission(id, query.token)

        await this.checkCorsDocumentBucket()

        return this.documentStoreService.getSignedUrl(document.bucket, document.key)
    }

    async renameFile(args: { name: string; override: Boolean; fileId: string }, requesterId: string) {
        const { fileId, name, override } = args
        const file = await this.getFile(fileId)

        // nothing change
        if (name && name === file.name) return file

        if (name && name !== file.name && override === false) {
            await this.checkFileName(name, file.folderId)
        }

        const oldFile = structuredClone(file)
        file.name = name
        file.key = file.key.replace(oldFile.name, name)
        file.updatedBy = requesterId

        try {
            await this.documentStoreService.copyFile(oldFile, file)

            const metadata = await this.documentStoreService.getMetadataObj(file.key)

            file.etag = metadata.etag
            file.location = metadata.selfLink

            await this.documentStoreService.deleteFile(oldFile)

            await file.save()
        } catch (error) {
            console.log('[RENAME] Rename document has failed: ', error)
            throw buildExceptionResponse(error)
        }

        return file
    }

    async documentGetFile(id: string, documentPermissions: any) {
        const file = await this.getFile(id)

        if (documentPermissions.userType === UserType.NORMAL_USER && !documentPermissions.fileIds.includes(file.id))
            throw OfficeError.DocumentFolderPermissionDenied

        return file
    }

    async documentGetFolder(id: string, documentPermissions: any) {
        const folder = await this.getFolder(id)

        if (documentPermissions.userType === UserType.NORMAL_USER && !documentPermissions.folderIds.includes(folder.id))
            throw OfficeError.DocumentFolderPermissionDenied

        return folder
    }

    // TODO:
    async documentTransferStorage() {
        const job = await this.documentStoreService.transferFromOutside()

        if (this.documentStoreService.jobRunningSuccess(job)) {
            return this.documentUpdateDBAfterTransfer()
        } else {
            // create cron to check util job success and update DB
        }
    }

    private async documentUpdateDBToGCloudAfterTransfer() {
        const files = await this.documentFileRepository.find()
        const locationGCS = 'https://www.googleapis.com'

        for (const file of files) {
            if (!file.location.startsWith(locationGCS)) {
                const metadata = await this.documentStoreService.getMetadataObj(file.key)

                file.etag = metadata.etag
                file.bucket = metadata.bucket
                file.location = metadata.selfLink
                file.size = metadata.size

                await file.save()
            }
        }
    }

    async documentUpdateDBAfterTransfer() {
        switch (process.env.DOCUMENT_STORE_SERVICE) {
            case STORE_SERVICE.AWS:
                return this.documentUpdateDBToAWSAfterTransfer()
            case STORE_SERVICE.GCLOUD:
            default:
                return this.documentUpdateDBToGCloudAfterTransfer()
        }
    }

    // TODO:
    private async documentUpdateDBToAWSAfterTransfer() {
        return Promise.resolve(undefined);
    }

    private async checkCorsDocumentBucket() {
        const check = await this.cacheService.get(DOCUMENT_BUCKET_CORS_ORIGIN)

        if (!check || check !== process.env.DOCUMENT_BUCKET_CORS_ORIGIN) {
            await this.documentStoreService.updateDocumentStoreCors()
            await this.cacheService.set(DOCUMENT_BUCKET_CORS_ORIGIN, process.env.DOCUMENT_BUCKET_CORS_ORIGIN)
        }
    }

    async restoreSize() {
        try {
            const files = await this.documentFileRepository.findBy({
                size: IsNull()
            })

            for (const file of files) {
                console.log('restore size for:', file.id, file.key)
                const metadata = await this.documentStoreService.getMetadataObj(file.key)
                file.size = metadata.size

                await file.save()
            }

            return 'done'
        } catch (e) {
            console.log('restoreSizeDocument error', e)

            return 'Bad request'
        }
    }

    private async createOrgChartDocumentDepartment(folder: DocumentFolder, args: DocumentFolderArgs) {
        const res = []
        const departments = await OfficeOrgChart.find({
            where: {
                id: In(args.departmentIds)
            }
        })
        for (const department of departments) {
            res.push(OrgChartDocument.create({
                documentId: folder.id,
                type: DocumentType.Folder,
                departmentId: department.id,
                createdBy: RequestContext.currentRequestId()
            }))
        }

        return res
    }

    private async createOrgChartDocumentUser(folder: DocumentFolder, args: DocumentFolderArgs) {
        const res = []
        const users = await OfficeUser.find({
            where: { id: In(args.userIds) }
        })

        for (const user of users) {
            res.push(OrgChartDocument.create({
                documentId: folder.id,
                type: DocumentType.Folder,
                userId: user.id,
                createdBy: RequestContext.currentRequestId()
            }))
        }

        return res;
    }

    private async getAndCountFolderTreeOfUser(parentId: string, documentPermissions: any) {
        const allOfUser = await this.documentFolderRepository.find({
            where: {
                id: In(documentPermissions.folderIds || [])
            }
        })

        const allIdValid = arrayConvertToDistinctAndNotNull(allOfUser.map(i => i.path.split('/')).flat(Infinity))

        return await this.documentFolderRepository.findAndCount({
            where: {
                parentId: parentId,
                id: In(allIdValid || [])
            }
        })
    }

    private async getFolderElementIdsForAdmin() {
        let documentIds
        const admin = await OfficeSysUser.findOne({
            where: {
                id: RequestContext.currentRequestId(),
            }
        })
        if (admin?.orgChartIds) {
            const folderIds = await this.allFolderIdsOfAdmin(admin)
            const fileIds = await this.getAllSysFileIdsByFolderIds(folderIds)
            const wikis = await this.wikiRepo.getAllOfFoldersByFolderIds(folderIds)

            documentIds = (folderIds || []).concat(fileIds || []).concat(wikis.map(i => i?.id) || [])
        }

        return documentIds
    }

    private async removeWikiOfDocuments(documents: DocumentFolder[]) {
        return this.wikiRepo.softRemoveAllOfFolderIds(documents.map(i => i.id))
    }

    async getAllUserIdCanViewDocument(id: string) {
        const orgDocs = await this.orgChartDocumentRepo.getAllByDocId(id)

        let userIds = arrayConvertToDistinctAndNotNull(orgDocs.flatMap(i => i.userId))
        let departmentIds = arrayConvertToDistinctAndNotNull(orgDocs.flatMap(i => i.departmentId))

        const departments = await this.userDepartmentRepo.getManyBy({ id: In(departmentIds) })

        return arrayConvertToDistinctAndNotNull([
            ...userIds,
            ...departments.flatMap(i => i.userId)
        ])
    }

    async getAllUserIdCanViewWiki(folderId: string, wikiId: string) {
        const orgDocs = await this.orgChartDocumentRepo.getAllByDocId(folderId)

        let userIds = arrayConvertToDistinctAndNotNull(orgDocs.flatMap(i => i.userId))
        let departmentIds = arrayConvertToDistinctAndNotNull(orgDocs.flatMap(i => i.departmentId))

        const departments = await this.userDepartmentRepo.getManyBy({ departmentId: In(departmentIds) })

        const denys = await OrgChartDocument.find({
            where: {
                documentId: wikiId,
                type: DocumentType.Wiki,
                effect: ObjectEffect.Deny
            }
        })

        const denyIds = denys.map(i => i.userId)

        return arrayConvertToDistinctAndNotNull([
            ...userIds,
            ...departments.flatMap(i => i?.userId)
        ].filter(i => !denyIds.includes(i)))
    }

    private async getAllDocumentAllowOfRequester(documentPermissions: any) {
        let res = []
        switch (documentPermissions.userType) {
            case UserType.NORMAL_USER:
                const wikis = await this.wikiRepo.getAllOfFoldersByFolderIds(documentPermissions.folderIds)
                res = (documentPermissions.folderIds || [])
                    .concat(documentPermissions.fileIds || [])
                    .concat(wikis.map(i => i?.id) || [])
                break
            case UserType.SYSTEM_USER:
                res = await this.getFolderElementIdsForAdmin()
                break
        }

        return arrayConvertToDistinctAndNotNull(res)
    }

    private async allFolderIdsOfAdmin(admin: OfficeSysUser) {
        const ids = await this.getAllSysFolderIds(admin.orgChartIds)

        const res = await this.documentFolderRepository.find({
            where: [
                {
                    id: In(ids || [])
                },
                {
                    createdBy: admin.id
                }
            ]
        })

        return res.map(i => i.id)
    }
}
