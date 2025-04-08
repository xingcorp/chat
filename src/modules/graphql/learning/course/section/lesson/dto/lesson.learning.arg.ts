import { Field, InputType, Int, OmitType } from "@nestjs/graphql";
import { LearnLesson, LearnSection } from "@models/entities";
import { ValidateIf } from "class-validator";
import { DefaultFilterInput } from "@common/args.common";
import {
    IsExistLessonLearningDbValidate
} from "@decorators/validation/db/learning/lesson/is-exist.lesson.learning.db.validate";
import {
    IsExistSectionLearningDbValidate
} from "@decorators/validation/db/learning/section/is-exist.section.learning.db.validate";
import { LessonMediaTypeEnum } from "@enum/learning/learning.enum";
import { ActiveStatus } from "@common/enum.common";

@InputType()
export class LearningLessonCreateInput {
    @Field(_type => String, { nullable: true })
    name: string

    @Field(_type => Int, { nullable: true })
    order: number

    @Field(_type => String, { nullable: true })
    description: string

    @Field(_type => LessonMediaTypeEnum, { nullable: true })
    mediaType: LessonMediaTypeEnum

    @Field(_type => [String], { nullable: true })
    embedUrls: string[]

    @Field(_type => [String], { nullable: true })
    attachmentIds: string[]

    @Field(_type => ActiveStatus, { nullable: true, defaultValue: ActiveStatus.Active })
    status: ActiveStatus

    @Field(_type => String, { nullable: true })
    @ValidateIf(o => o.sectionId)
    @IsExistSectionLearningDbValidate()
    sectionId: string

    section?: LearnSection
}

@InputType()
export class LearningLessonUpdateInput extends OmitType(LearningLessonCreateInput, ['order']) {
    @Field(_type => String, { nullable: true })
    @ValidateIf(o => o.lessonId)
    @IsExistLessonLearningDbValidate()
    lessonId: string

    lesson?: LearnLesson
}

@InputType()
export class LearningLessonUpsertInput extends LearningLessonCreateInput {
    @Field(_type => String, { nullable: true })
    @ValidateIf(o => o.lessonId)
    @IsExistLessonLearningDbValidate()
    lessonId: string
    
    lesson?: LearnLesson
}

@InputType()
export class LearningLessonFilterInput extends DefaultFilterInput { }