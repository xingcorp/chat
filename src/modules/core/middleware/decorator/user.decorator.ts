import { createParamDecorator, ExecutionContext } from '@nestjs/common'
import { GqlExecutionContext } from '@nestjs/graphql'
import { ApolloError } from 'apollo-server-express'
import { DocumentFile, OfficeOrgChart, OfficeUser, OrgChartDocument, UserDepartment } from 'src/models/entities'
import { DocumentFolder, DocumentScope } from 'src/models/entities/document.folder'
import { DocumentType } from 'src/models/entities/org.chart.document'
import { ILike, In } from 'typeorm'
import { UserType } from '../guard/service.action'
import { OfficeSysUser } from "@models/entities/system.user";

export const UserIp = createParamDecorator(
  (data: unknown, context: ExecutionContext) => {
    const ctx = GqlExecutionContext.create(context);

    return ctx.getContext().req?.get('x-forwarded-for') ?? null;
  },
);

export const RequesterId = createParamDecorator(
  async (_data: string, ctx: ExecutionContext) => {
    const { req } = GqlExecutionContext.create(ctx).getContext()
    if (!req.requesterId) {
      throw new ApolloError('Không tìm thấy thông tin người dùng', '403')
    }

    return req.requesterId
  }
)

export const Requester = createParamDecorator(
  async (_data: string, ctx: ExecutionContext) => {
    const { req } = GqlExecutionContext.create(ctx).getContext()
    if (!req.requesterId) {
      throw new ApolloError('Không tìm thấy thông tin người dùng', '403')
    }

    return req.requesterInfo.user
  }
)


export const OfficeRequesterId = createParamDecorator(
  async (_data: string, ctx: ExecutionContext) => {
    const { req } = GqlExecutionContext.create(ctx).getContext()
    if (!req.officeRequesterId) {
      throw new ApolloError('Không tìm thấy thông tin người dùng', '403')
    }
    return req.officeRequesterId
  }
)

export const OfficeRequester = createParamDecorator(
  async (_data: string, ctx: ExecutionContext) => {
    const { req } = GqlExecutionContext.create(ctx).getContext()
    if (!req.officeUser) {
      throw new ApolloError('Không tìm thấy thông tin người dùng', '403')
    }
    return req.officeUser
  }
)

export const OfficeUserType = createParamDecorator(
  async (_data: string, ctx: ExecutionContext) => {
    const { req } = GqlExecutionContext.create(ctx).getContext()
    if (!req.requesterId) {
      throw new ApolloError('Không tìm thấy thông tin người dùng', '403')
    }

    const userType = req.requesterInfo?.user?.type
    return userType
  }
)

export const DocumentPermissions = createParamDecorator(
  async (_data: string, ctx: ExecutionContext) => {
    const { req } = GqlExecutionContext.create(ctx).getContext()
    if (!req.requesterId) {
      throw new ApolloError('Không tìm thấy thông tin người dùng', '403')
    }

    const userType = req.requesterInfo?.user?.type
    console.log("userType: ", userType)
    if (userType === UserType.SYSTEM_USER) {
      return {
        userType: userType,
        folderIds: null,
        folders: null,
        fileIds: null,
        files: null
      }
    }
    const officeUser = await OfficeUser.findOne({
      where: { iamUserId: req.requesterId }
    })

    if (!officeUser) {
      throw new ApolloError('Không tìm thấy thông tin nhân viên', '404')
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

    /*http://13.251.55.174:8080/browse/SOF-1985*/
    /*const whereOptions: any[] = [{
      scope: DocumentScope.Public
    }]
    for (const iterator of allowFolders) {
      whereOptions.push({
        path: ILike(`%${iterator.documentId}%`)
      })
    }*/

    const folders = await DocumentFolder.find({
      where: {
        id: In(allowFolders.map(i => i.documentId))
      }
    })
    const files = await DocumentFile.find({
      where: folders.map(folder => {
        return {
          path: ILike(`%${folder.id}%`)
        }
      })
    })

    return {
      userType: userType,
      folderIds: folders.map(fo => fo.id),
      folders: folders,
      fileIds: files.map(fi => fi.id),
      files: files
    }
  }
)

export const RootOfficeOrganization = createParamDecorator(
  async (_data: string, ctx: ExecutionContext) => {
    const { req } = GqlExecutionContext.create(ctx).getContext()
    if (!req.requesterId) {
      throw new ApolloError('Không tìm thấy thông tin người dùng', '403')
    }

    const userType = req.requesterInfo?.user?.type
    console.log("userType: ", userType)
    if (userType === UserType.SYSTEM_USER) {
      return null
    }
    const officeUser = await OfficeUser.findOne({
      where: { iamUserId: req.requesterId }
    })

    if (!officeUser) {
      throw new ApolloError('Không tìm thấy thông tin nhân viên', '404')
    }

    const userDepartments = await UserDepartment.find({
      where: {
        userId: officeUser.id
      }
    })

    let rootIds = []
    const departments = await OfficeOrgChart.find({
      where: {
        id: In(userDepartments.map(ud => ud.departmentId))
      }
    })
    for (const dept of departments) {
      const root = dept.path.split("/")[1]
      if (!rootIds.includes(root)) rootIds.push(root)
    }

    return rootIds
  }
)

export const CurrentOrganization = createParamDecorator(
  async (_data: string, ctx: ExecutionContext) => {
    const { req } = GqlExecutionContext.create(ctx).getContext()
    if (!req.organizationId) {
      throw new ApolloError('Không tìm thấy thông tin tổ chức', '403')
    }

    return req.requesterInfo.organization
  }
)

export const OrganizationId = createParamDecorator(
  async (_data: string, ctx: ExecutionContext) => {
    const { req } = GqlExecutionContext.create(ctx).getContext()
    if (!req.organizationId) {
      throw new ApolloError('Không tìm thấy thông tin tổ chức', '403')
    }

    return req.organizationId
  }
)

export const OrganizationCode = createParamDecorator(
  async (_data: string, ctx: ExecutionContext) => {
    const { req } = GqlExecutionContext.create(ctx).getContext()
    if (!req.organizationId) {
      throw new ApolloError('Không tìm thấy thông tin tổ chức', '403')
    }
    return req.requesterInfo.organization ? req.requesterInfo.organization.code : null
  }
)

export const CurrentBusinessRole = createParamDecorator(
  async (_data: string, ctx: ExecutionContext) => {
    const { req } = GqlExecutionContext.create(ctx).getContext()
    if (!req.businessRoleId) {
      throw new ApolloError('Không tìm thấy thông tin vai trò', '403')
    }

    return req.requesterInfo.businessRole
  }
)

export const BusinessRoleId = createParamDecorator(
  async (_data: string, ctx: ExecutionContext) => {
    const { req } = GqlExecutionContext.create(ctx).getContext()
    if (!req.requesterInfo || !req.requesterInfo.businessRoleIds || req.requesterInfo.businessRoleIds.length === 0) {
      throw new ApolloError('Không tìm thấy thông tin vai trò', '403')
    }

    return req.requesterInfo.businessRoleIds[0]
  }
)

export const BusinessRoleCode = createParamDecorator(
  async (_data: string, ctx: ExecutionContext) => {
    const { req } = GqlExecutionContext.create(ctx).getContext()
    if (!req.requesterInfo || !req.requesterInfo.businessRoles || req.requesterInfo.businessRoles.length === 0) {
      throw new ApolloError('Không tìm thấy thông tin vai trò', '403')
    }

    return req.requesterInfo.businessRoles[0].code
  }
)

export const MultiBusinessRoleCodes = createParamDecorator(
  async (_data: string, ctx: ExecutionContext) => {
    const { req } = GqlExecutionContext.create(ctx).getContext()
    if (!req.requesterInfo || !req.requesterInfo.businessRoles || req.requesterInfo.businessRoles.length === 0) {
      throw new ApolloError('Không tìm thấy thông tin vai trò', '403')
    }

    return req.requesterInfo.businessRoles.reduce((prev, current) => {
      prev.push(current.code)
      return prev
    }, [])
  }
)

export const PermissionInfo = createParamDecorator(
  async (_data: string, ctx: ExecutionContext) => {
    const { req } = GqlExecutionContext.create(ctx).getContext()
    return req.permissionInfo
  }
)

export const PermissionResource = createParamDecorator(
  async (_data: string, ctx: ExecutionContext) => {
    const { req } = GqlExecutionContext.create(ctx).getContext()
    return req.permissionInfo.resources
  }
)

export const IsSystemOfficeAdmin = createParamDecorator(
  async (_data: string, ctx: ExecutionContext) => {
    const { req } = GqlExecutionContext.create(ctx).getContext()
    if (!req.requesterId) {
      throw new ApolloError('Không tìm thấy thông tin người dùng', '403')
    }
    const officeUser = await OfficeSysUser.findOne({
      where: { iamUserId: req.requesterId }
    })
    if (!officeUser) {
      throw new ApolloError('Không tìm thấy quản lý', '403')
    }
    return !officeUser.orgChartIds
  }
)