import { Injectable } from '@nestjs/common';
import * as _ from 'lodash';
import { CourseLearningRepo, LessonLearningRepo, SectionLearningRepo, StudentLearningRepo } from "@models/repositories";
import {
    LearningCourseCreateInput, LearningCourseFilterInput, LearningCourseReOrderSectionInput,
    LearningCourseUpdateInput, LearningCourseUpsertInput
} from "@modules/graphql/learning/course/dto/course.learning.arg";
import { OfficeError } from "@common/office.error";
import { RequestContext } from "@common/context/request.context";
import { LearningSectionUpsertInput } from './section/dto/section.learning.arg';
import { RandomHelper } from '@common/random';
import { LearningLessonUpsertInput } from './section/lesson/dto/lesson.learning.arg';
import { LoggerService } from '@core/common/logger.service';
import { LearnCourse, LearnSection, LearnStudent, OfficeUser } from '@models/entities';
import { CourseStatusEnum } from '@enum/learning/learning.enum';
import { SectionLearningService } from './section/section.learning.service';

@Injectable()
export class CourseLearningService {
    logger = new LoggerService(CourseLearningService.name)

    constructor(private readonly courseLearningRepo: CourseLearningRepo,
        private readonly sectionLearningRepo: SectionLearningRepo,
        private readonly lessonLearningRepo: LessonLearningRepo,
        private readonly studentLearningRepo: StudentLearningRepo,
        private readonly sectionLearningService: SectionLearningService
    ) {
    }

    async create(args: LearningCourseCreateInput): Promise<LearnCourse> {
        return this.courseLearningRepo.manager.transaction(async transactionalEntityManager => {
            try {
                const data = structuredClone(args);
                // Create course
                const course = await transactionalEntityManager.save(
                    this.courseLearningRepo.create({
                        ...data,
                        timeStartAt: new Date(Date.parse(`01 Jan 1970 ${args.timeStartAt}:00 GMT`)),
                        timeCloseAt: new Date(Date.parse(`01 Jan 1970 ${args.timeCloseAt}:00 GMT`)),
                        enrollStartAt: args.enrollStartAt ? new Date(args.enrollStartAt) : null,
                        enrollEndAt: args.enrollEndAt ? new Date(args.enrollEndAt) : null,
                        startClassAt: args.startClassAt ? new Date(args.startClassAt) : null,
                        closeClassAt: args.closeClassAt ? new Date(args.closeClassAt) : null,
                        orgChart: await RequestContext.getRootOrg(),
                        proposer: args.proposer ? args.proposer : await RequestContext.currentUser(),
                        teacher: args.teacher
                    })
                );

                // Create students
                const batchStudents = args.students.map((s: OfficeUser) => {
                    return this.studentLearningRepo.create({
                        user: s,
                        course: course,
                    })
                })

                await transactionalEntityManager.save(
                    batchStudents
                );

                if (!args.sections) {
                    return course;
                }

                // Prepare lessons data
                const batchLessons: LearningLessonUpsertInput[] = [];

                args.sections.forEach((s: LearningSectionUpsertInput) => {
                    s.course = course;
                    if (!s.sectionId) {
                        s.sectionId = RandomHelper.generateUUID();
                        s.id = s.sectionId
                    }

                    if (s.lessons) {
                        s.lessons.forEach((l: LearningLessonUpsertInput) => {
                            l.sectionId = s.sectionId;
                            batchLessons.push(l);
                        });
                    }
                })

                // Create sections and lessons within transaction
                await transactionalEntityManager.save(
                    this.sectionLearningRepo.create(args.sections)
                );

                await transactionalEntityManager.save(
                    this.lessonLearningRepo.create(batchLessons)
                );

                return course;
            } catch (error) {
                this.logger.error('Failed to create course:', error);
                throw new Error('Failed to create course. Transaction rolled back.');
            }
        });
    }

    async update(args: LearningCourseUpdateInput) {
        const course = args.course
        if (course.status === CourseStatusEnum.ENDED) {
            throw OfficeError.LearningCourseClosed
        }
        course.name = args.name ? args.name : course.name
        course.code = args.code ? args.code : course.code
        course.joinType = args.joinType ? args.joinType : course.joinType
        course.totalStudent = args.totalStudent ? args.totalStudent : course.totalStudent
        course.trainingTypes = args.trainingTypes ? args.trainingTypes : course.trainingTypes
        course.project = args.project ? args.project : course.project
        course.teacherId = args.teacherId ? args.teacherId : course.teacherId
        course.proposerId = args.proposerId ? args.proposerId : course.proposerId
        course.timeStartAt = args.timeStartAt ? new Date(Date.parse(`01 Jan 1970 ${args.timeStartAt}:00 GMT`)) : course.timeStartAt
        course.timeCloseAt = args.timeCloseAt ? new Date(Date.parse(`01 Jan 1970 ${args.timeCloseAt}:00 GMT`)) : course.timeCloseAt
        course.enrollStartAt = args.enrollStartAt ? new Date(args.enrollStartAt) : course.enrollStartAt
        course.enrollEndAt = args.enrollEndAt ? new Date(args.enrollEndAt) : course.enrollEndAt
        course.startClassAt = args.startClassAt ? new Date(args.startClassAt) : course.startClassAt
        course.closeClassAt = args.closeClassAt ? new Date(args.closeClassAt) : course.closeClassAt

        return this.courseLearningRepo.manager.transaction(async transactionalEntityManager => {
            try {

                await transactionalEntityManager.save(
                    course
                );

                if (args.students) {
                    // Get current students
                    const currentStudents = await this.studentLearningRepo.getManyBy({ courseId: course.id }, null, ['id', 'userId']);
                    const removeStudentIds = _.difference(currentStudents.map(s => s.userId), args.studentIds)
                    const addStudentIds = _.difference(args.studentIds, currentStudents.map(s => s.userId))

                    if (removeStudentIds.length > 0) {
                        await transactionalEntityManager
                            .createQueryBuilder()
                            .delete()
                            .from(LearnStudent)
                            .where('userId IN (:...removeStudentIds)', { removeStudentIds })
                            .andWhere('courseId = :courseId', { courseId: course.id })
                            .execute();
                    }

                    if (addStudentIds.length > 0) {
                        const batchStudents = addStudentIds.map((s: string) => {
                            return this.studentLearningRepo.create({
                                user: { id: s },
                                course: course,
                            })
                        })

                        await transactionalEntityManager.save(
                            this.studentLearningRepo.create(batchStudents)
                        );
                    }
                }

                if (args.sections) {
                    await this.sectionLearningService.bulkUpsert(args.sections, course, transactionalEntityManager)
                }

                return course;
            } catch (error) {
                this.logger.error('Failed to update course:', error);
                throw new Error(error);
            }
        });
    }

    upsert(args: LearningCourseUpsertInput) {
        if (args.courseId) {
            return this.update(args)
        }

        return this.create(args)
    }

    async get(id: string): Promise<LearnCourse> {
        return this.courseLearningRepo.getBy({ id }, ['sections', 'students']);
    }

    async list(filter: LearningCourseFilterInput) {
        const [data, total] = await this.courseLearningRepo.listByFilter(filter)

        return {
            total: total as number,
            count: data.length,
            records: data
        }
    }

    async remove(id: string) {
        const course = await this.courseLearningRepo.getBy({ id })

        if (!course) {
            throw OfficeError.LearningCourseNotFound
        }

        course.deletedBy = RequestContext.currentRequestId()
        await course.save()
        await course.softRemove()

        return id;
    }

    async reOrderSection(args: LearningCourseReOrderSectionInput) {
        for (const index of args.sectionIds) {
            const section = args.sections.find(section => section.id === args.sectionIds[index])

            section.order = parseInt(index) + 1
            section.updatedBy = RequestContext.currentId()
            section.course = args.course

            await section.save()
        }

        return args.course;
    }

    async isProjectHasStudent(projectId: string): Promise<boolean> {
        const courses = await this.courseLearningRepo.createQueryBuilder('course')
            .leftJoinAndSelect('course.students', 'students')
            .where('course.projectId = :projectId', { projectId })
            .select(['course.id', 'students.id'])
            .getMany()
        return !!(courses.map(c => c.students).flat().length)
    }

    async isCoursesOfProjectIsEnd(projectId: string): Promise<boolean> {
        const courses = await this.courseLearningRepo.createQueryBuilder('course')
            .where('course.projectId = :projectId', { projectId })
            .select(['course.id', 'course.status'])
            .getMany()
        return !!(courses.find(c => c.status != CourseStatusEnum.ENDED))
    }
}
