import { Field, Float, InputType, Int, registerEnumType } from "@nestjs/graphql";
import { ValidateIf, ValidateNested } from "class-validator";
import {
    IsCodeNotExistProjectLearningDbValidate
} from "@decorators/validation/db/learning/project/is-code-not-exist.project.learning.db.validate";
import {
    IsNameNotExistProjectLearningDbValidate
} from "@decorators/validation/db/learning/project/is-name-not-exist.project.learning.db.validate";
import { LearnProjectStatusEnum, ProjectTimeTypeEnum } from "@enum/learning/learning.enum";
import { IsGreaterThan } from "@decorators/validation/utils/is-greater-than.validate";
import {
    IsExistSkillLearningDbValidate
} from "@decorators/validation/db/learning/skill/is-exist.skill.learning.db.validate";
import { LearnCertification, LearnProject, LearnSkill, OfficeOrgChart } from "@models/entities";
import {
    IsExistCertificateLearningDbValidate
} from "@decorators/validation/db/learning/certificate/is-exist.certificate.learning.db.validate";
import {
    IsExistProjectLearningDbValidate
} from "@decorators/validation/db/learning/project/is-exist.project.learning.db.validate";
import { IsExistDepartmentDbValidate } from "@decorators/validation/db/org-chart/is-exist.department.db.validate";
import { DefaultFilterInput, OrderDirection } from "@common/args.common";
import { IsExistExaminationLearningDbValidate } from "@decorators/validation/db/learning/examination/is-exist.examination.learning.db.validate";
import { Type } from "class-transformer";
import { IsPropertyNameExistValidate } from "@decorators/validation/db/is-exist.code.course.learning.db.validate";

enum ProjectSortBy {
    ALPHABET_ASC = 'ALPHABET_ASC',
    ALPHABET_DESC = 'ALPHABET_DESC',
    CREATED_DESC = 'CREATED_DESC',
    CREATED_ASC = 'CREATED_ASC'
}

registerEnumType(ProjectSortBy, {
    name: 'ProjectSortBy',
    // description: 'Các tùy chọn sắp xếp cho project learning',
});

@InputType()
export class LearningProjectCreateInput {
    @Field({ nullable: true })
    @ValidateIf(o => o.code)
    @IsCodeNotExistProjectLearningDbValidate()
    code: string

    @Field({ nullable: true })
    @ValidateIf(o => o.name)
    @IsNameNotExistProjectLearningDbValidate()
    name: string

    @Field(_type => LearnProjectStatusEnum, { nullable: true })
    status: LearnProjectStatusEnum

    @Field(_type => Boolean, { nullable: true })
    isHide: boolean

    @Field(_type => Int, { nullable: true })
    maxNumberOfStudent: number

    @Field(_type => ProjectTimeTypeEnum, { nullable: true })
    timeType: ProjectTimeTypeEnum

    @Field(_type => Int, { nullable: true })
    dayOfEvent: number

    @Field(_type => Float, { nullable: true })
    startDate: Date

    @Field(_type => Float, { nullable: true })
    @ValidateIf(o => o.endDate && o.startDate)
    @IsGreaterThan('startDate', {
        message: 'WrongEndDatePeriod'
    })
    endDate: Date

    @Field({ nullable: true })
    summary: string

    @Field({ nullable: true })
    content: string

    @Field(() => [String], { nullable: true })
    // @ValidateIf(o => o.avatarIds && o.avatarIds.length)
    // @IsExistAttachmentsIamValidate()
    avatarIds: string[]

    @Field(() => [String], { nullable: true })
    // @ValidateIf(o => o.videoIds && o.videoIds.length)
    // @IsExistAttachmentsIamValidate()
    videoIds: string[]

    @Field(_type => [String], { nullable: true })
    @ValidateIf(o => o.departmentIds)
    @IsExistDepartmentDbValidate()
    departmentIds: string[]

    departments?: OfficeOrgChart[] = null

    @Field(() => [String], { nullable: true })
    @ValidateIf(o => o.skillIds)
    @IsExistSkillLearningDbValidate()
    skillIds: string[]

    skills?: LearnSkill[] = null

    @Field(() => [String], { nullable: true })
    @ValidateIf(o => o.certificateIds)
    @IsExistCertificateLearningDbValidate()
    certificateIds: string[]

    certificates?: LearnCertification[] = null

    @Field(() => [String], { nullable: true })
    @IsExistExaminationLearningDbValidate()
    requiredLearnExaminationIds: string[]

    @Field(() => [String], { nullable: true })
    @ValidateIf(o => o.requiredLearnProjectIds)
    @IsExistProjectLearningDbValidate()
    requiredLearnProjectIds: string[]

    @Field(() => [String], { nullable: true })
    requiredSurveyIds: string[]

    @Field(() => [String], { nullable: true })
    @ValidateIf(o => o.requiredCertificateIds)
    @IsExistCertificateLearningDbValidate()
    requiredCertificateIds: string[]

    @Field(() => Float, { nullable: true })
    timeToPass: number

    @Field(() => Float, { nullable: true })
    scoreToPass: number
}

@InputType()
export class LearningProjectUpdateInput extends LearningProjectCreateInput {
    @Field(() => String, { nullable: false })
    @ValidateIf(o => o.projectId)
    @IsExistProjectLearningDbValidate()
    projectId: string

    project?: LearnProject

    @Field(() => Boolean, { nullable: true })
    isPin: boolean
}

@InputType()
export class LearningProjectUpsertInput extends LearningProjectUpdateInput {
    @Field(() => String, { nullable: true })
    @ValidateIf(o => o.projectId)
    @IsExistProjectLearningDbValidate()
    projectId: string

    project?: LearnProject

    @Field(() => Boolean, { nullable: true })
    isPin: boolean
}

@InputType()
export class OrderListProjectArgs {
    @Field(() => String, { nullable: false })
    @ValidateIf(o => o.key)
    @IsPropertyNameExistValidate(LearnProject)
    key: string

    @Field(() => OrderDirection, { nullable: false })
    direction: OrderDirection
}

@InputType()
export class LearningProjectFilterInput extends DefaultFilterInput {
    @Field(() => [OrderListProjectArgs], { nullable: true })
    @ValidateNested({ each: true })
    @Type(() => OrderListProjectArgs)
    orderBy: OrderListProjectArgs[]

    @Field(_type => LearnProjectStatusEnum, { nullable: true })
    status: LearnProjectStatusEnum

    @Field(() => [String], { nullable: true })
    departmentIds?: string[];

    @Field(() => [String], { nullable: true })
    skillIds?: string[];

    @Field(() => Float, { nullable: true })
    startDate?: Date;

    @Field(() => Float, { nullable: true })
    endDate?: Date;
}