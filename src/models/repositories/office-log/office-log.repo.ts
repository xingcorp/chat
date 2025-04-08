import { Injectable } from "@nestjs/common";
import { DataSource, Repository } from "typeorm";
import { OfficeLogs } from "@models/entities";
import { OfficeFeatureLogAttachmentType, OfficeLogType } from "@enum/logs/logs.enum";
import { RequestContext } from "@common/context/request.context";
import { OfficeLogCommentArgs, OfficeLogHistoryArgs } from "@modules/graphql/log/dto/log.args";
import { OfficeAttachmentType } from "../../../arguments/logs/office-logs.args";

@Injectable()
export class OfficeLogRepo extends Repository<OfficeLogs> {
    constructor(
        private dataSource: DataSource,
    ) {
        super(OfficeLogs, dataSource.createEntityManager());
    }

    private getAttachmentType(param: { attachmentIds?: string[], imageIds?: string[] }) {
        const res: OfficeAttachmentType[] = []

        if (param.attachmentIds) {
            res.push({
                type: OfficeFeatureLogAttachmentType.Attachment,
                list: param.attachmentIds,
            });
        }

        if (param.imageIds) {
            res.push({
                type: OfficeFeatureLogAttachmentType.Image,
                list: param.imageIds,
            });
        }

        return JSON.stringify(res)
    }

    async commentCreate(param: OfficeLogCommentArgs) {
        const currentId = await RequestContext.currentId()

        const objectIds = structuredClone(param.attachmentIds ?? [])
        objectIds.push(...(param.imageIds ?? []))

        const log = this.create({
            type: OfficeLogType.Comment,
            ...param,
            objectType: this.getAttachmentType(param),
            objectIds,
            createdBy: currentId,
            updatedBy: currentId,
        })

        log.userCreator = await RequestContext.currentUser()
        log.adminCreator = await RequestContext.currentAdmin()
        log.rootOrgId = await RequestContext.getOnlyRootOrgId()
        log.orgCharts = await RequestContext.getOrgCharts()

        return log
    }

    async historyCreate(param: OfficeLogHistoryArgs) {
        const currentId = await RequestContext.currentId()

        const log = this.create({
            type: OfficeLogType.History,
            ...param,
            logs: JSON.stringify(param.logs),
            createdBy: currentId,
            updatedBy: currentId,
        })

        log.userCreator = await RequestContext.currentUser()
        log.adminCreator = await RequestContext.currentAdmin()
        log.rootOrgId = await RequestContext.getOnlyRootOrgId()
        log.orgCharts = await RequestContext.getOrgCharts()

        return log
    }

    async getAllByRelationId(id: string, relations?: string[]) {
        const query = this.createQueryBuilder('qb')

        if (relations) {
            relations.map(i => query.leftJoinAndSelect(`qb.${i}`, `${i}`))
        }

        return query
            .where({
                featureLogId: id
            })
            .getMany()
    }
}