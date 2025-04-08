import { Injectable } from '@nestjs/common';
import { Cron, CronExpression, Timeout } from "@nestjs/schedule";
import { TaskService } from "@modules/graphql/task/task/task.service";
import { OfficeBlockType } from "@enum/block/block.enum";
import { OfficeFilter, OfficeTask } from "@models/entities";
import { TaskTypeEnum } from "@enum/task/task.enum";
import { FilterRelationType } from "@enum/filter/filter.enum";

@Injectable()
export class TaskJobService {

    constructor(
        private readonly taskService: TaskService
    ) {
    }

    // @Cron(CronExpression.EVERY_10_MINUTES, {
    /*@Cron("0 0 09 * * *", {
        name: 'NotifyTaskNeedToDoneInTime',
        timeZone: process.env.TIMEZONE
    })*/
    async notifyTaskNeedToDoneInTime() {
        try {
            return this.taskService.notifyTaskNeedToDoneInTime()
        } catch (e) {
            console.log('NotifyTaskNeedToDoneInTime err', e)
        }
    }

    // @Cron(CronExpression.EVERY_10_MINUTES, {
    /*@Cron("0 0 09 * * *", {
        name: 'NotifyTaskLate',
        timeZone: process.env.TIMEZONE
    })*/
    async notifyTaskLate() {
        try {
            return this.taskService.notifyTaskLate()
        } catch (e) {
            console.log('NotifyTaskLate err', e)
        }
    }

    /*done*/
    // @Timeout(10000)
    async seedDataForNewCr() {
        return this.taskService.seedDataForNewCr()
    }

    /*@Cron("0 *!/15 * * * *", {
        name: 'CreateReportTask',
        timeZone: process.env.TIMEZONE
    })*/
    async createReportTask() {
        try {
            return this.taskService.taskReportCreate()
        } catch (e) {
            console.log('CreateReportTask err', e)
        }
    }

    /*Done*/
    // @Timeout(10000)
    async seedDataCreator() {
        return this.taskService.seedDataCreator()
    }

    @Timeout(10000)
    async updateDataFilterForNewTypeReportArise() {
        const count = await OfficeFilter.countBy({relationType: FilterRelationType.TaskReport})

        if (count) return

        console.log('updateDataFilterForNewTypeReportArise run')

        await OfficeFilter.createQueryBuilder()
            .update()
            .set({relationType: FilterRelationType.TaskReport})
            .where({relationType: FilterRelationType.Task})
            .execute()

        console.log('updateDataFilterForNewTypeReportArise done')
    }
}
