import { Injectable } from "@nestjs/common";
import { Connection, EntitySubscriberInterface, InsertEvent, ObjectLiteral, UpdateEvent } from "typeorm";
import { InjectConnection } from "@nestjs/typeorm";
import {  NotificationCampaign, NotificationScheduleType } from "@models/entities/notification.campaign";
import { NotificationSchedule } from "@models/entities/notification.schedule";
import { DayOfWeek } from "@common/constant.common";

@Injectable()
// @EventSubscriber()
export class CampaignSubscriber implements EntitySubscriberInterface<NotificationCampaign> {
    private entity: ObjectLiteral;
    private weekDays: number[];

    constructor(
        @InjectConnection() readonly connection: Connection,
    ) {
        connection.subscribers.push(this);
    }

    /**
     * Indicates that this subscriber only listen to NotificationCampaign events.
     */
    listenTo() {
        return NotificationCampaign
    }

    /**
     * Called after entity insertion.
     */
    async afterInsert(event: InsertEvent<NotificationCampaign>) {
        try {
            this.entity = event.entity
            await this.createSchedule()


        } catch (e) {
            console.log('afterInsert NotificationCampaign error', e)
        }
    }

    /**
     * Called after entity update.
     */
    async afterUpdate(event: UpdateEvent<NotificationCampaign>) {
        try {
            this.entity = event.entity
            await this.removeOldSchedule()
            await this.createSchedule()
        } catch (e) {
            console.log('afterUpdate NotificationCampaign error', e)
        }
    }

    private async genScheduleTimeRecord(): Promise<Date[]> {
        if (this.entity.type === NotificationScheduleType.Now) return []
        const now = new Date()
        const result = []

        await this.getWeekDaysNumber()
        this.entity.startTimeIn.map(time => {
            const currentDate = new Date(this.entity.startAt);
            currentDate.setMilliseconds(0)
            currentDate.setSeconds(0)
            currentDate.setHours(time / 60 - this.entity.timeZone)
            currentDate.setMinutes(time % 60)

            while (currentDate <= this.entity.endAt) {
                if (currentDate >= this.entity.startAt && currentDate > now) {
                    let add = true
                    switch (this.entity.type) {
                        case NotificationScheduleType.Weekly:
                            if (!this.weekDays.includes(currentDate.getDay())) add = false
                            break
                        case NotificationScheduleType.Monthly:
                            if (!this.entity.monthDays.includes(currentDate.getDate())) add = false
                            break
                    }
                    if (add) result.push(new Date(currentDate));
                }

                currentDate.setDate(currentDate.getDate() + 1);
            }
        })

        return result
    }

    private async getWeekDaysNumber() {
        if (!this.entity?.weekDays) {
            this.weekDays = []
            return
        }

        this.weekDays = this.entity.weekDays.map(w => {
            if (w === DayOfWeek.Sun) {
                return 0
            } else if (w === DayOfWeek.Mon) {
                return 1
            } else if (w === DayOfWeek.Tue) {
                return 2
            } else if (w === DayOfWeek.Wed) {
                return 3
            } else if (w === DayOfWeek.Thu) {
                return 4
            } else if (w === DayOfWeek.Fri) {
                return 5
            } else if (w === DayOfWeek.Sat) {
                return 6
            }
        })
    }

    private async createSchedule() {
        const schedules: NotificationSchedule[] = []

        switch (this.entity.type) {
            case NotificationScheduleType.Now:
                schedules.push(NotificationSchedule.create({
                    campaignId: this.entity.id,
                    scheduleAt: new Date()
                }))
                break
            case NotificationScheduleType.Daily:
            case NotificationScheduleType.Weekly:
            case NotificationScheduleType.Monthly:
                const listSchedules = await this.genScheduleTimeRecord()
                listSchedules.map(d => {
                    schedules.push(NotificationSchedule.create({
                        campaignId: this.entity.id,
                        scheduleAt: d
                    }))
                })
                break
        }

        if (schedules.length > 0) await NotificationSchedule.save(schedules)
    }

    private async removeOldSchedule() {
        const schedules = await NotificationSchedule.find({
            where: {campaignId: this.entity.id,}
        })

        for (const schedule of schedules) {
            await schedule.softRemove()
        }
    }
}