import { Module } from '@nestjs/common';
import { ProjectLearningModule } from './project/project.learning.module';
import { SkillLearningModule } from './skill/skill.learning.module';
import { CertificateLearningModule } from './certificate/certificate.learning.module';
import { CourseLearningModule } from './course/course.learning.module';
import { ModelModule } from '@models/model.module';
import { AddressLearningModule } from './address/address.learning.module';

@Module({
    providers: [],
    imports: [
        ModelModule,
        ProjectLearningModule,
        SkillLearningModule,
        CertificateLearningModule,
        CourseLearningModule,
        AddressLearningModule
    ]
})
export class LearningModule {
}
