import { LearnCourse, LearnStudent } from "@models/entities";
import { Injectable } from "@nestjs/common";
import { Connection, EntitySubscriberInterface, InsertEvent } from "typeorm";
import { UserScheduleRepo } from "@models/repositories";
import { ScheduleType, UserSchedule } from "@models/entities/user.schedule";
import { combineDateAndTime, getWeekDayNumber } from "@utils/datetime.utils";

@Injectable()
export class LearnStudentSubscriber implements EntitySubscriberInterface<LearnStudent> {
    constructor(
        readonly connection: Connection,
        private readonly userScheduleRepo: UserScheduleRepo
    ) {
        connection.subscribers.push(this);
    }

    listenTo() {
        return LearnStudent
    }

    async afterInsert(event: InsertEvent<LearnStudent>) {
        const learnStudent = event.entity;
        const course = learnStudent.course;
        const learningDays = this.calculateLearningDays(course);
        
        const userSchedules: UserSchedule[] = learningDays.map(learningDate => {
            const startAt = combineDateAndTime(learningDate, course.timeStartAt);
            const endAt = combineDateAndTime(learningDate, course.timeCloseAt);

            return this.userScheduleRepo.create({
                ownerId: learnStudent.userId,
                startAt,
                endAt,
                type: ScheduleType.Learning,
                learnStudentId: learnStudent.id,
            });
        });
        await event.manager.getRepository(UserSchedule).save(userSchedules);
    }

    private calculateLearningDays(course: LearnCourse): Date[] {
        let currentDate = new Date(course.startClassAt);
        const endDate = new Date(course.closeClassAt);
        const learningDays: Date[] = [];
        const weekDayNumber = getWeekDayNumber(course.pickedDays)
        while (currentDate <= endDate) {
            if (weekDayNumber.includes(currentDate.getDay())) {
                learningDays.push(new Date(currentDate));
            }
            currentDate.setDate(currentDate.getDate() + 1);
        }

        return learningDays;
    }
}