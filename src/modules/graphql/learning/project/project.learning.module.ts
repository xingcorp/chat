import { Module } from '@nestjs/common';
import { ProjectLearningService } from './project.learning.service';
import { ProjectLearningResolver } from './project.learning.resolver';
import { OfficeProjectLearningResolver } from './office.project.learning.resolver';
import { ModelModule } from '@models/model.module';
import { CommonModule } from '@core/common/common.module';
import { CourseLearningModule } from '../course/course.learning.module';

@Module({
    imports: [
        ModelModule,
        CommonModule,
        CourseLearningModule
    ],
    providers: [
        ProjectLearningService,
        ProjectLearningResolver,
        OfficeProjectLearningResolver,
    ]
})
export class ProjectLearningModule {
}
