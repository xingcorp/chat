import { Injectable } from '@nestjs/common';
import * as _ from 'lodash';
import { LessonLearningRepo } from "@models/repositories";
import { OfficeError } from "@common/office.error";
import { RequestContext } from "@common/context/request.context";
import { LearningLessonCreateInput, LearningLessonFilterInput, LearningLessonUpdateInput, LearningLessonUpsertInput } from './dto/lesson.learning.arg';
import { LearnLesson, LearnSection } from '@models/entities';
import { EntityManager } from 'typeorm';
import { LoggerService } from '@core/common/logger.service';

@Injectable()
export class LessonLearningService {
    logger = new LoggerService(LessonLearningService.name)
    constructor(private readonly lessonLearningRepo: LessonLearningRepo) {
    }

    async create(args: LearningLessonCreateInput): Promise<LearnLesson> {
        const lesson = this.lessonLearningRepo.create(args)

        await lesson.save()

        return lesson;
    }

    async update(args: LearningLessonUpdateInput) {
        const lesson = args.lesson

        lesson.name = args.name

        await lesson.save()

        return lesson;
    }

    bulkCreate(args: LearningLessonCreateInput[]): Promise<LearnLesson[]> {
        const section = this.lessonLearningRepo.create(args)

        return this.lessonLearningRepo.save(section);
    }

    upsert(args: LearningLessonUpsertInput) {
        if (args.lessonId) {
            return this.update(args)
        }

        return this.create(args)
    }

    async bulkUpsert(args: LearningLessonUpsertInput[], section: LearnSection, transactionalEntityManager: EntityManager) {
        try {
            const currentLessons = await this.lessonLearningRepo.getManyBy({ sectionId: section.id });
            const addLessons = args.filter(s => !s.lessonId)
            const updateLessons = args.filter(s => s.lessonId)
            const removeLessonIds = _.difference(currentLessons.map(s => s.id), updateLessons.map(s => s.lessonId))

            const batchSaveLessons = [];
            addLessons.forEach((lesson: LearningLessonUpsertInput) => {
                lesson.sectionId = section.id;
                batchSaveLessons.push(this.lessonLearningRepo.create(lesson));
            })

            if (removeLessonIds.length > 0) {
                await transactionalEntityManager
                    .createQueryBuilder()
                    .delete()
                    .from(LearnLesson)
                    .where('id IN (:...id)', { id: removeLessonIds })
                    .execute();
            }

            if (updateLessons.length > 0) {
                updateLessons.forEach((lesson: LearningLessonUpsertInput) => {
                    const updateLesson = _.merge({}, lesson.lesson, lesson);
                    batchSaveLessons.push(this.lessonLearningRepo.create(updateLesson));
                })
            }

            if (batchSaveLessons.length > 0) {
                await transactionalEntityManager.save(LearnLesson, batchSaveLessons);
            }
        } catch (error) {
            this.logger.error('Failed to update LESSON:', error);
            throw new Error(error);
        }
    }

    get(id: string) {
        return this.lessonLearningRepo.getBy({ id });
    }

    async list(filter: LearningLessonFilterInput) {
        const [data, total] = await this.lessonLearningRepo.listByFilter(filter)

        return {
            total: total as number,
            count: data.length,
            records: data
        }
    }

    async remove(id: string) {
        const lesson = await this.lessonLearningRepo.getBy({ id })

        if (!lesson) {
            throw OfficeError.LearningLessonNotFound
        }

        lesson.createdBy = RequestContext.currentRequestId()
        await lesson.save()
        await lesson.softRemove()

        return id;
    }
}
