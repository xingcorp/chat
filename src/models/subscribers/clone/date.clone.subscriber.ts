import { Injectable } from "@nestjs/common";
import { Connection, EntitySubscriberInterface, ObjectLiteral, UpdateEvent } from "typeorm";
import { CloneByDate } from "@models/entities";
import { InjectConnection, InjectRepository } from "@nestjs/typeorm";
import { CloneDatePeriodEnum, CloneDateTypeEnum } from "@enum/clone/date.clone.enum";
import { RequestContext } from "@common/context/request.context";
import { OfficeTaskLogRepo, OfficeTaskRepo, OfficeUserRepo } from "@models/repositories";
import { TaskLogService } from "@modules/graphql/task/task-log/task-log.service";

@Injectable()
// @EventSubscriber()
export class DateCloneSubscriber implements EntitySubscriberInterface<CloneByDate> {
    private entity: ObjectLiteral;
    private eventUpdate: UpdateEvent<CloneByDate>;

    constructor(
        @InjectConnection() readonly connection: Connection,
        @InjectRepository(OfficeTaskLogRepo)
        private readonly officeTaskLogRepo: OfficeTaskLogRepo,
        @InjectRepository(OfficeTaskRepo)
        private readonly officeTaskRepo: OfficeTaskRepo,
        private readonly taskLogService: TaskLogService,
    ) {
        connection.subscribers.push(this);
    }

    /**
     * Indicates that this subscriber only listen to CloneByDate events.
     */
    listenTo() {
        return CloneByDate
    }

    /**
     * Called before entity update.
     */
    async beforeUpdate(event: UpdateEvent<CloneByDate>) {
        const isChangePeriodType = event.updatedColumns.map(i => i.propertyName).includes('periodType')

        if (isChangePeriodType) {
            const newPeriodType = event.entity.periodType

            switch (newPeriodType) {
                case CloneDatePeriodEnum.Daily:
                    event.entity.weekDays = null
                    event.entity.monthDays = null
                    break
                case CloneDatePeriodEnum.Weekly:
                    event.entity.monthDays = null
                    break
                case CloneDatePeriodEnum.Monthly:
                    event.entity.weekDays = null
                    break
            }
        }
    }

    /**
     * Called after entity update.
     */
    async afterUpdate(event: UpdateEvent<CloneByDate>) {
        try {
            this.eventUpdate = event

            switch (event.entity.relationType) {
                case CloneDateTypeEnum.TaskReportConfig:
                    return this.afterUpdateTaskReportConfig()
            }
        } catch (e) {
            console.log('Called after CloneByDate update error', e)
        }
    }

    private async afterUpdateTaskReportConfig() {
        const event = this.eventUpdate

        this.entity = event.entity
        const oldVal = event.databaseEntity
        const newVal = event.entity
        const fieldsChange = [...new Set([
            ...event.updatedColumns.map(i => i.propertyName),
            ...event.updatedRelations.map(i => i.propertyName)
        ])]
        .filter(
            i => ['startAt', 'endAt', 'startTimeIn', 'periodType', 'weekDays', 'monthDays', 'relationData'].includes(i)
        )

        const data = {
            creator: await RequestContext.currentUser(),
            logs: await this.taskLogService.createLogsByCloneDate(fieldsChange, oldVal, newVal),
            task: await this.officeTaskRepo.findOneBy({id: oldVal.relationId})
        }

        if (data.logs.length) await this.officeTaskLogRepo.storeHistoryTaskUpdate(data, event.manager)
    }
}