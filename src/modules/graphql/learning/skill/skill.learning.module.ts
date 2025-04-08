import { Module } from '@nestjs/common';
import { SkillLearningService } from './skill.learning.service';
import { SkillLearningResolver } from './skill.learning.resolver';
import {
    IsNameNotExistSkillLearningDbValidateConstraint
} from "@decorators/validation/db/learning/skill/is-name-not-exist.skill.learning.db.validate";
import { OfficeOrgChartRepo, OfficeSysUserRepo, OfficeUserRepo, SkillLearningRepo } from "@models/repositories";
import {
    IsExistSkillLearningDbValidateConstraint
} from "@decorators/validation/db/learning/skill/is-exist.skill.learning.db.validate";
import { OfficeSkillLearningResolver } from './office.skill.learning.resolver';

@Module({
    providers: [
        SkillLearningService,
        SkillLearningResolver,
        OfficeSysUserRepo,
        OfficeOrgChartRepo,
        OfficeUserRepo,
        SkillLearningRepo,
        IsNameNotExistSkillLearningDbValidateConstraint,
        IsExistSkillLearningDbValidateConstraint,
        OfficeSkillLearningResolver,
    ]
})
export class SkillLearningModule {
}
