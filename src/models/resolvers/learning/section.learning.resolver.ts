import { Parent, ResolveField, Resolver } from "@nestjs/graphql";
import {
    LearnLesson,
    LearnSection,
} from "@models/entities";
import { LessonLearningRepo } from "@models/repositories";
import { LoggerService } from "@core/common/logger.service";


@Resolver(_of => LearnSection)
export class LearnSectionResolver {
    logger = new LoggerService(LearnSectionResolver.name)
    constructor(
        private lessonLearningRepo: LessonLearningRepo,
    ) {
    }

    @ResolveField('lessons', _return => [LearnLesson], { nullable: true })
    async lessons(
        @Parent() root: LearnSection
    ) {
        try {
            if (root.lessons) {
                return root.lessons
            }
            return await this.lessonLearningRepo.getManyBy({ sectionId: root.id })
        } catch (error) {
            this.logger.error(`Field lessons`, error);
            return []
        }
    }
}