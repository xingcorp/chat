import { In } from "typeorm";
import { DocumentWiki, OfficeOrgChart, OfficeUser, OrgChartDocument, UserDepartment } from "@models/entities";
import { ObjectEffect } from "@models/entities/org.chart.document";
import { arrayConvertToDistinctAndNotNull } from "@utils/array.utils";

export class DocumentHelpers {

    static async allUserIdPermissionOfDocument(documentId: string) {
        const data = await OrgChartDocument.find({
            where: [{documentId}]
        })

        const allowOrgIds = data
            .filter(i => i.departmentId && i.effect === ObjectEffect.Allow)
            .map(i => i.departmentId)

        const allowUserIdsByDepartment = await UserDepartment.find({where: {departmentId: In(allowOrgIds ?? [])}})

        const allowUserIds = arrayConvertToDistinctAndNotNull(data
            .filter(i => i.userId && i.effect === ObjectEffect.Allow)
            .map(i => i.userId)
            .concat(allowUserIdsByDepartment.map(i => i.userId) ?? []))

        const denyUserIds = data
            .filter(i => i.userId && i.effect === ObjectEffect.Deny)
            .map(i => i.userId)

        return {
            allows: allowUserIds,
            denys: denyUserIds
        }
    }

    static async allUserIdPermissionOfWiki(wikiId: string) {
        const wiki = await DocumentWiki.createQueryBuilder('qb')
            .leftJoinAndSelect('qb.folder', 'folder')
            .where({id: wikiId})
            .getOne()

        if (!wiki) {
            return {
                allows: null,
                denys: null
            }
        }

        const permissionOfFolder = await this.allUserIdPermissionOfDocument(wiki.folder.id)

        const permissionOfWiki = await this.allUserIdPermissionOfDocument(wiki.id)

        return {
            allows: arrayConvertToDistinctAndNotNull(
                permissionOfFolder.allows
                .concat(permissionOfWiki.allows)
                .filter(i => !permissionOfWiki.denys.includes(i))
            ),
            denys: permissionOfWiki.denys,
        }
    }

    static async allUserPermissionOfDocument(param: {allows: string[]; denys: string[]}) {
        return {
            allows: OfficeUser.findBy({id: In(param.allows ?? [])}),
            denys: OfficeUser.findBy({id: In(param.denys ?? [])}),
        }
    }

    static async allUserPermissionOfDocumentFollowDepartment(param: {allows: string[]; denys: string[]}) {
        const users = await OfficeUser.findBy({id: In(param.allows.concat(param.denys) ?? [])})
        const userDepartments = await UserDepartment.find({where: {userId: In(users.map(i => i?.id) ?? [])}})
        const departments = await OfficeOrgChart.find({where: {id: In(userDepartments.map(i => i?.departmentId) ?? [])}})

        const resAllows = []
        const resDenys = []
        for (const department of departments) {
            const listUserIds = userDepartments.filter(i => i.departmentId === department.id).map(i => i?.userId)

            if (listUserIds.length) {
                let listUsers = users.filter(i => listUserIds.includes(i.id) && param.allows.includes(i.id))
                if (listUsers.length) {
                    resAllows.push({
                        department: department,
                        users: listUsers
                    })
                }

                listUsers = users.filter(i => listUserIds.includes(i.id) && param.denys.includes(i.id))
                if (listUsers.length) {
                    resDenys.push({
                        department: department,
                        users: listUsers
                    })
                }
            }
        }

        return {
            allows: resAllows,
            denys: resDenys,
        }
    }
}