import { Injectable } from "@nestjs/common";
import { DataSource, In, Repository } from "typeorm";
import { ApprovalForm, OrgChartApprovalForm } from "@models/entities";
import { RequestContext } from "@common/context/request.context";

@Injectable()
export class ApprovalFormRepo extends Repository<ApprovalForm> {
    constructor(
        private dataSource: DataSource,
    ) {
        super(ApprovalForm, dataSource.createEntityManager());
    }

    async getOneBy(where: any, relations?: string[]) {
        const query = this.createQueryBuilder('qb')

        if (relations) {
            relations.map(i => query.leftJoinAndSelect(`qb.${i}`, `${i}`))
        }

        return query
            .where(where)
            .getOne()
    }

    async getAllOfDepartmentIds(departmentIds: string[]) {
        return this.createQueryBuilder('ap')
            .leftJoinAndMapMany('ap.departments', OrgChartApprovalForm, 'oc', 'oc."formId" = ap.id::text')
            .where(`oc."departmentId" in (:...departmentIds)`, {departmentIds})
            .getMany()
    }
}