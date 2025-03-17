import { Injectable } from '@nestjs/common';
import * as _ from 'lodash';
import { LessonLearningRepo, SectionLearningRepo } from "@models/repositories";
import {
    LearningSectionCreateInput, LearningSectionFilterInput, LearningSectionReOrderLessonInput,
    LearningSectionUpdateInput, LearningSectionUpsertInput
} from "@modules/graphql/learning/course/section/dto/section.learning.arg";
import { RequestContext } from "@common/context/request.context";
import { OfficeError } from "@common/office.error";
import { LearnCourse, LearnLesson, LearnSection } from '@models/entities';
import { RandomHelper } from '@common/random';
import { LearningLessonUpsertInput } from './lesson/dto/lesson.learning.arg';
import { EntityManager } from 'typeorm';
import { LessonLearningService } from './lesson/lesson.learning.service';
import { LoggerService } from '@core/common/logger.service';

@Injectable()
export class SectionLearningService {
    logger = new LoggerService(SectionLearningService.name)
    constructor(
        private readonly sectionLearningRepo: SectionLearningRepo,
        private readonly lessonLearningRepo: LessonLearningRepo,
        private readonly lessonLearningService: LessonLearningService
    ) { }

    async create(args: LearningSectionCreateInput) {
        const section = this.sectionLearningRepo.create(args)

        await section.save()

        return section;
    }

    bulkCreate(args: LearningSectionCreateInput[]) {
        const section = this.sectionLearningRepo.create(args)

        return this.sectionLearningRepo.save(section);
    }

    async update(args: LearningSectionUpdateInput) {
        const section = args.section

        section.name = args.name

        await section.save()

        return section;
    }

    upsert(args: LearningSectionUpsertInput) {
        if (args.sectionId) {
            return this.update(args)
        }

        return this.create(args)
    }

    async bulkUpsert(args: LearningSectionUpsertInput[], course: LearnCourse, transactionalEntityManager: EntityManager) {
        try {
            const currentSections = await this.sectionLearningRepo.getManyBy({ courseId: course.id }, null, ['id']);
            const addSections = args.filter(s => !s.sectionId)
            const updateSections = args.filter(s => s.sectionId)
            const removeSectionIds = _.difference(currentSections.map(s => s.id), updateSections.map(s => s.sectionId))

            const batchSaveSections: LearningSectionUpsertInput[] = [];
            const batchLessons: LearningLessonUpsertInput[] = [];

            addSections.forEach((s: LearningSectionUpsertInput) => {
                s.course = course;
                s.sectionId = RandomHelper.generateUUID();
                s.id = s.sectionId;

                if (s.lessons) {
                    s.lessons.forEach((l: LearningLessonUpsertInput) => {
                        l.sectionId = s.sectionId;
                        batchLessons.push(l);
                    });
                }
                batchSaveSections.push(s);
            })

            if (removeSectionIds.length > 0) {
                await transactionalEntityManager
                    .createQueryBuilder()
                    .delete()
                    .from(LearnLesson)
                    .where('sectionId IN (:...id)', { id: removeSectionIds })
                    .execute();
                await transactionalEntityManager
                    .createQueryBuilder()
                    .delete()
                    .from(LearnSection)
                    .where('id IN (:...id)', { id: removeSectionIds })
                    .execute();
            }

            if (updateSections.length > 0) {
                for (const s of updateSections) {
                    const updateSection = _.merge({}, s.section, s);
                    
                    if (s.lessons) {
                        await this.lessonLearningService.bulkUpsert(s.lessons, s.section, transactionalEntityManager)
                    }
                    delete updateSection.lessons;
                    batchSaveSections.push(updateSection);
                }
            }

            if (batchSaveSections.length > 0) {
                await transactionalEntityManager.save(
                    this.sectionLearningRepo.create(batchSaveSections)
                );
            }

            if (batchLessons.length > 0) {
                await transactionalEntityManager.save(
                    this.lessonLearningRepo.create(batchLessons)
                );
            }
        } catch (error) {
            this.logger.error('Failed to update SECTION:', error);
            throw new Error(error);
        }
    }

    get(id: string) {
        return this.sectionLearningRepo.getBy({ id });
    }

    async list(filter: LearningSectionFilterInput) {
        const [data, total] = await this.sectionLearningRepo.listByFilter(filter)

        return {
            total: total as number,
            count: data.length,
            records: data
        }
    }

    async remove(id: string) {
        const section = await this.sectionLearningRepo.getBy({ id })

        if (!section) {
            throw OfficeError.LearningSectionNotFound
        }

        section.createdBy = RequestContext.currentRequestId()
        await section.save()
        await section.softRemove()

        return id;
    }

    async reOrderLesson(args: LearningSectionReOrderLessonInput) {
        for (const index of args.lessonIds) {
            const lesson = args.lessons.find(lesson => lesson.id === args.lessonIds[index])

            lesson.order = parseInt(index) + 1
            lesson.updatedBy = RequestContext.currentId()
            lesson.section = args.section

            await lesson.save()
        }

        return args.section;
    }
}
