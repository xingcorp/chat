import { Inject, Injectable, forwardRef } from "@nestjs/common";
import { InjectConnection } from "@nestjs/typeorm";
import { OfficeOrgChart, OfficeUser, UserDepartment } from "src/models/entities";
import { File, FileCleanType } from "src/modules/core/storage/objects/file";
import { StorageService } from "src/modules/core/storage/storage.service";
import { Brackets, Connection, ILike, In, Not } from "typeorm";
import * as ExcelJS from 'exceljs';
import {
    EditOrgChartArgs,
    OrgChartFilter,
    OrgChartFullListFilter,
    UserOrgChartFilter
} from "@modules/graphql/management/orgchart/orgchart.args";
import { OfficeOrgChartRepo } from "@models/repositories/office-org-chart.repo";
import { OfficeError } from "@common/office.error";
import { OfficeSysUserRepo } from "@models/repositories/office-sys-user.repo";
import { RequestContext } from "@common/context/request.context";
import { ObjectStatus } from "@models/entities/profile.info.block";
import { OfficeUserRepo } from "@models/repositories";
import { SelectQueryBuilder } from "typeorm/query-builder/SelectQueryBuilder";

@Injectable()
export class OrgChartService {
    constructor(
        @Inject(forwardRef(() => StorageService))
        private readonly storageService: StorageService,

        @InjectConnection()
        private readonly connection: Connection,

        private orgChartRepo: OfficeOrgChartRepo,
        private officeSysUserRepo: OfficeSysUserRepo,
        private officeUserRepo: OfficeUserRepo,
    ) { }

    public async orgChartRawQuery() {
        let query = `SELECT
                        orgchart.id as "id",
                        array_length(string_to_array(orgchart."path", '/'), 1) - 1 as "Cấp",
                        orgchart.code as "Mã",
                        orgchart."name" as "Tên*",
                        ooc.code as "Mã cấp trên trực tiếp",
                        ooc."name" as "Tên cấp trên trực tiếp"
                    FROM office."office-org-charts" orgchart 
                    left join office."office-org-charts" ooc 
                        on ooc.id::text = orgchart."parentId" and orgchart."deletedAt" is null
                    where orgchart."deletedAt" is null
                    order by orgchart."path" asc, "Cấp" asc`

        // const pagingQuery = `${query} limit ${limit} offset ${offset}`

        return this.connection.query(query)
    }

    public async orgChartExport(
        token: string
    ): Promise<File> {
        const workbook = new ExcelJS.Workbook()
        // workbook.creator = requester.fullname ? requester.fullname : requester.email
        // workbook.lastModifiedBy = requester.fullname ? requester.fullname : requester.email
        workbook.created = new Date()
        workbook.modified = new Date()
        workbook.lastPrinted = new Date()
        const dataStyle: Partial<ExcelJS.Style> = {
            alignment: { vertical: 'middle', horizontal: 'left' },
            font: { size: 13 },
        }

        //Request group sheet
        const chartSheet = workbook.addWorksheet('Chart')
        chartSheet.columns = [
            { header: 'id', key: 'id', width: 30, style: dataStyle },
            { header: 'Cấp', key: 'level', width: 20, style: dataStyle },
            { header: 'Mã', key: 'code', width: 30, style: dataStyle },
            { header: 'Tên*', key: 'name', width: 30, style: dataStyle },
            { header: 'Mã cấp trên trực tiếp', key: 'parentCode', width: 30, style: dataStyle },
            { header: 'Tên cấp trên trực tiếp', key: 'parentName', width: 30, style: dataStyle },
        ]
        chartSheet.autoFilter = { from: 'A1', to: 'F1' }
        chartSheet.getRow(1).font = { 'bold': true, 'size': 13 }

        const orgCharts = await this.orgChartRawQuery()

        for (const orgChart of orgCharts) {
            chartSheet.addRow([...Object.values(orgChart)])
        }

        const excelName = `OFFICE_ORGCHART.xlsx`
        const excelBuffer = await workbook.xlsx.writeBuffer()
        const newTempfile = await this.storageService.uploadObject(
            token,
            excelBuffer,
            excelName,
            'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
            'orgchart',
            FileCleanType.Never
        )

        return newTempfile
    }

    async getListByFilters(filter: OrgChartFilter, oogIds?: string[]) {
        filter.size = filter.size ? filter.size : 20 //1
        filter.page = filter.page ? (filter.page - 1) : 0

        let query = OfficeOrgChart.createQueryBuilder('qb')
            .where({})
            .take(filter.size)
            .skip(filter.page * filter.size)
            .orderBy('qb.createdAt', 'DESC')


        if (!oogIds) oogIds = RequestContext.currentListOrgIds()

        query.andWhere(`qb.id::text IN (:...oogIds)`, {oogIds})

        if (filter && filter.keyword) {
            query.andWhere(new Brackets(db => {
                    db.where(`unaccent(LOWER(qb.name)) ILIKE unaccent(LOWER(:keyword))`, { keyword: `%${filter.keyword.trim()}%`})
                        .orWhere(`unaccent(LOWER(qb.code)) ILIKE unaccent(LOWER(:keyword))`, { keyword: `%${filter.keyword.trim()}%`})
                        .orWhere(`unaccent(LOWER(qb.note)) ILIKE unaccent(LOWER(:keyword))`, { keyword: `%${filter.keyword.trim()}%`})
                }))
        }

        const [list, count] = await query.getManyAndCount()

        return {
            total: count,
            count: list.length,
            orgCharts: list
        }
    }

    async getAllBySysUser(filter: OrgChartFullListFilter) {

        let allIds = RequestContext.currentOrgData('listOrgIdAll')

        if (RequestContext.isSysUser()) {
            const sys = await RequestContext.currentAdmin()

            if (!sys.orgChartIds){
                const orgs = await OfficeOrgChart.find()
                allIds = orgs.map(i => i.id)
            }
        }

        const query = this.orgChartRepo.createQueryBuilder('qb')
            .where({
                id: In(RequestContext.currentOrgData('listOrgIdAll'))
            })

        const path = await this.filterQueryGetOrgChart(query, filter)

        const [data, total] = await query.getManyAndCount()

        return {
            total: total,
            count: data.length,
            orgCharts: (path
                ? data.map(i => ({
                    ...i,
                    path: i.path.replace(path, "")
                }))
                : data) as OfficeOrgChart[]
        }
    }

    async managementOrgChartOnOff(id: string) {
        const requesterId = RequestContext.currentRequestId()
        const existedOrg = await this.orgChartRepo.findOne({
            where: {
                id: id
            }
        })

        if (!existedOrg) {
            throw OfficeError.OrgChartNotFound
        }

        if (existedOrg.status === ObjectStatus.Inactive) {
            existedOrg.status = ObjectStatus.Active
            await existedOrg.save()
            await existedOrg.reload()

            return existedOrg
        }

        const relationOrgs = await this.orgChartRepo.find({
            where: {
                path: ILike(`%${existedOrg.id}%`)
            }
        })
        // console.log("relationOrgs: ", relationOrgs)
        const relationOrgIds = relationOrgs.map(o => {
            o.updatedBy = requesterId
            o.status = ObjectStatus.Inactive
            return o.id
        })
        console.log("relationOrgIds: ", relationOrgIds)
        //check nhân sự thuộc đơn vị
        const departmentUsers = await UserDepartment.find({
            where: {
                departmentId: In(relationOrgIds)
            }
        })

        const users = await this.officeUserRepo.find({
            where: {
                id: In(departmentUsers.map(i => i?.userId)),
                status: ObjectStatus.Active
            }
        })

        if (users.length > 0) throw OfficeError.OrgChartEmployeeNotEmpty

        await this.orgChartRepo.save(relationOrgs)
        await existedOrg.reload()

        return existedOrg
    }

    async getAllUserOfAllOrg(filter: UserOrgChartFilter) {
        return this.officeUserRepo.getAndCountWithFilter(filter)
    }

    private async filterQueryGetOrgChart(query: SelectQueryBuilder<OfficeOrgChart>, filter: OrgChartFullListFilter) {
        let root = null
        if (filter?.rootId) {
            let root = await OfficeOrgChart.findOne({ where: { id: filter.rootId } })
            if (!root) throw OfficeError.OrgChartNotFound

            query.andWhere({
                path: ILike(`%${root.path}%`)
            })
        }

        if (filter?.keyword) {
            query.andWhere(new Brackets(db => {
                db.where(`unaccent(LOWER(qb.name)) ILIKE unaccent(LOWER(:keyword))`, { keyword: `%${filter.keyword.trim()}%` })
                db.where(`unaccent(LOWER(qb.code)) ILIKE unaccent(LOWER(:keyword))`, { keyword: `%${filter.keyword.trim()}%` })
            }))
        }

        if (filter?.statuses && filter?.statuses?.length) {
            query.andWhere({
                status: In(filter?.statuses)
            })
        }

        return root?.path
    }

    async managementEditOrgChart(args: EditOrgChartArgs) {
        const requesterId = RequestContext.currentRequestId()
        const existedOrg = await OfficeOrgChart.findOne({
            where: {
                id: args.id
            }
        })

        if (!existedOrg) {
            throw OfficeError.OrgChartNotFound
        }

        if (args.name && args.name !== existedOrg.name) {
            const where: any = [{
                name: args.name,
                parentId: args.parentId ? args.parentId : existedOrg.parentId
            }]

            if (args.parentId) {
                where.push({
                    name: args.name,
                    id: args.parentId
                })
            }

            const checkName = await OfficeOrgChart.findOne({
                where
            })

            if (checkName) throw OfficeError.OrgChartNameExisted
            existedOrg.name = args.name
        }
        if (args.note !== undefined) existedOrg.note = args.note
        if (args.status && existedOrg.status !== args.status) {
            const {status} = await this.managementOrgChartOnOff(existedOrg.id)
            existedOrg.status = status
        }
        if (args.parentId && args.parentId !== existedOrg.parentId) {
            //check valid parentId
            const childOrgs = await OfficeOrgChart.find({
                where: {
                    path: ILike(`%${existedOrg.id}%`),
                    id: Not(existedOrg.id)
                }
            })
            const childIds = childOrgs.map(o => o.id)
            if (args.parentId === existedOrg.id || childIds.includes(args.parentId)) {
                throw OfficeError.OrgChartParentInvalid
            }

            const oldPath = existedOrg.path
            var path = existedOrg.path
            if (args.parentId === 'root') {
                path = `/${existedOrg.id}`
            } else {
                const parent = await OfficeOrgChart.findOne({
                    where: {
                        id: args.parentId
                    }
                })

                if (!parent) throw OfficeError.OrgChartNotFound
                path = `${parent.path}/${existedOrg.id}`
            }

            existedOrg.parentId = args.parentId
            existedOrg.path = path

            //update children
            // console.log("childOrgs: ", childOrgs)
            for (const org of childOrgs) {
                org.path = org.path.replace(oldPath, existedOrg.path)
            }
            await OfficeOrgChart.save(childOrgs)
        }

        if (args.approverId && args.approverId !== existedOrg.approverId) {
            const officeUser = await OfficeUser.findOne({
                where: {
                    id: args.approverId
                }
            })

            if (!officeUser) throw OfficeError.EmployeeNotFound
            existedOrg.approverId = args.approverId
        } else if (!args.approverId) {
            /*remove*/
            existedOrg.approverId = null
        }

        existedOrg.updatedBy = requesterId
        return existedOrg.save()
    }
}