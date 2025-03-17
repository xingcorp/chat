import { Injectable } from "@nestjs/common";
import { DataSource, EntityManager, Repository } from "typeorm";
import { OfficeTask, OfficeTaskLog, OfficeUser } from "@models/entities";
import { TaskAction, TaskLogType } from "@enum/task/task.enum";
import { OfficeAttachmentType } from "../../../arguments/logs/office-logs.args";
import { OfficeFeatureLogAttachmentType } from "@enum/logs/logs.enum";

@Injectable()
export class OfficeTaskLogRepo extends Repository<OfficeTaskLog> {
    constructor(private dataSource: DataSource) {
        super(OfficeTaskLog, dataSource.createEntityManager());
    }

    createComment(param: {comment: string; attachmentIds: string[]; imageIds: string[]}) {
        const objectIds = structuredClone(param.attachmentIds ?? [])
        objectIds.push(...(param.imageIds ?? []))

        return this.create({
            type: TaskLogType.Comment,
            description: param.comment,
            objectType: this.getAttachmentType(param),
            objectIds,
        })
    }

    async getCommentById(id: string) {
        return this.findOne({
            relations: ['creator'],
            where: { id }
        })
    }

    createHistory(data: any) {
        const log = this.create()

        log.logs = JSON.stringify(data.logs)

        log.creator = data.creator
        log.task = data.task
        log.type = data.type
        log.note = data?.note
        log.createdBy = data.creator?.id
        log.updatedBy = data.creator?.id

        return log
    }

    async storeHistoryTaskCreate(entity: OfficeTask, manager: EntityManager = null) {
        const data = {
            creator: entity.creator,
            type: TaskLogType.History,
            task: entity,
            logs: [
                {
                    action: TaskAction.Create,
                    actionAt: new Date(entity.createdAt).getTime(),
                    taskType: entity?.taskType,
                    taskKind: entity?.taskKind,
                }
            ]
        }

        if (manager) return manager.getRepository(OfficeTaskLog).save(this.createHistory(data));

        return this.save(this.createHistory(data))
    }

    async storeHistoryTaskUpdate(data: { creator: OfficeUser; task: OfficeTask; logs: any[]; note?: string }, manager: EntityManager = this.dataSource.manager) {
        if (!data.logs.length) return

        data['type'] = TaskLogType.History

        const log = this.createHistory(data)

        if (manager) return manager.getRepository(OfficeTaskLog).save(log);

        return this.save(log)
    }

    private getAttachmentType(param: { comment: string; attachmentIds: string[]; imageIds: string[] }) {
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
}