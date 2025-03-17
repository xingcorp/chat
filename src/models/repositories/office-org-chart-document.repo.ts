import { Injectable } from "@nestjs/common";
import { DataSource, IsNull, Not, Repository } from "typeorm";
import { OrgChartDocument } from "@models/entities";
import { RequestContext } from "@common/context/request.context";
import { DocumentType, ObjectEffect } from "@models/entities/org.chart.document";

@Injectable()
export class OfficeOrgChartDocumentRepo extends Repository<OrgChartDocument> {
    constructor(private dataSource: DataSource) {
        super(OrgChartDocument, dataSource.createEntityManager());
    }

    async getAllByDepartmentIds(ids: string[]) {
        return this.createQueryBuilder('qb')
            .where(`qb."departmentId" IN (:...ids)`, {ids})
            .orWhere({
                createdBy: RequestContext.currentRequestId()
            })
            .getMany()
    }

    async getAllDocIdsByDepartmentIds(ids: string[]) {
        const list = await this.getAllByDepartmentIds(ids)

        return list.map(i => i.documentId)
    }

    async getAllDocIdsOfSys() {
        const orgIds = await RequestContext.currentListOrgIds()

        return this.getAllDocIdsByDepartmentIds(orgIds)
    }

    async getAllByDocId(documentId: string) {
        return this.createQueryBuilder()
            .where({documentId})
            .getMany()
    }

    async permissionUserUpdate(id: string, type: DocumentType, param: { denyIds: string[]; allowIds: string[] }) {
        await this.createQueryBuilder()
            .delete()
            .where({
                documentId: id,
                type,
                userId: Not(IsNull())
            })
            .execute()

        if (Array.isArray(param.allowIds)) {
            for (const userId of param.allowIds) {
                const data = this.create({
                    documentId: id,
                    type,
                    userId,
                })

                await data.save()
            }
        }

        if (Array.isArray(param.denyIds)) {
            for (const userId of param.denyIds) {
                const data = this.create({
                    documentId: id,
                    type,
                    userId,
                    effect: ObjectEffect.Deny
                })

                await data.save()
            }
        }
    }
}