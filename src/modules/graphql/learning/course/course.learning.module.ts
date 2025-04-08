import { Module } from '@nestjs/common';
import { CourseLearningService } from './course.learning.service';
import { CourseLearningResolver } from './course.learning.resolver';
import { OfficeCourseLearningResolver } from './office.course.learning.resolver';
import { ModelModule } from '@models/model.module';
import { SectionLearningService } from './section/section.learning.service';
import { SectionLearningResolver } from './section/section.learning.resolver';
import { OfficeSectionLearningResolver } from './section/office.section.learning.resolver';
import { LessonLearningService } from './section/lesson/lesson.learning.service';
import { LessonLearningResolver } from './section/lesson/lesson.learning.resolver';
import { OfficeLessonLearningResolver } from './section/lesson/office.lesson.learning.resolver';

@Module({
    imports: [ModelModule],
    providers: [
        CourseLearningService,
        CourseLearningResolver,
        OfficeCourseLearningResolver,
        SectionLearningService,
        SectionLearningResolver,
        OfficeSectionLearningResolver,
        LessonLearningService,
        LessonLearningResolver,
        OfficeLessonLearningResolver,
    ],
    exports: [CourseLearningService]
})
export class CourseLearningModule {
}
