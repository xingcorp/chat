import { Field, InputType, Int, OmitType } from "@nestjs/graphql";
import { LearnCourse, LearnLesson, LearnSection } from "@models/entities";
import { ValidateIf, ValidateNested } from "class-validator";
import { DefaultFilterInput } from "@common/args.common";
import {
    IsExistSectionLearningDbValidate
} from "@decorators/validation/db/learning/section/is-exist.section.learning.db.validate";
import {
    IsExistLessonLearningDbValidate
} from "@decorators/validation/db/learning/lesson/is-exist.lesson.learning.db.validate";
import { LearningLessonUpsertInput } from "../lesson/dto/lesson.learning.arg";
import { IsExistCourseLearningDbValidate } from "@decorators/validation/db/learning/course/is-exist.course.learning.db.validate";
import { Type } from "class-transformer";

@InputType()
export class LearningSectionCreateInput {
    @Field(_type => String, { nullable: true })
    name: string

    @Field(_type => String, { nullable: true })
    description: string

    @Field(_type => Int, { nullable: true })
    order: number

    @Field(_type => [LearningLessonUpsertInput], { nullable: true })
    @ValidateIf(o => o.lessons && o.lessons.length)
    @ValidateNested({ each: true })
    @Type(() => LearningLessonUpsertInput)
    lessons: LearningLessonUpsertInput[]

    @Field(_type => String, { nullable: true })
    @ValidateIf(o => o.courseId)
    @IsExistCourseLearningDbValidate()
    courseId: string

    course?: LearnCourse
}

@InputType()
export class LearningSectionUpdateInput extends OmitType(LearningSectionCreateInput, ['order']) {
    @Field(_type => String, { nullable: true })
    @ValidateIf(o => o.sectionId)
    @IsExistSectionLearningDbValidate()
    sectionId: string

    section?: LearnSection
}

@InputType()
export class LearningSectionUpsertInput extends LearningSectionCreateInput {
    @Field(_type => String, { nullable: true })
    @ValidateIf(o => o.sectionId)
    @IsExistSectionLearningDbValidate()
    sectionId: string

    id: string

    section?: LearnSection
}

@InputType()
export class LearningSectionFilterInput extends DefaultFilterInput { }

@InputType()
export class LearningSectionReOrderLessonInput {
    @Field(_type => String, { nullable: false })
    @IsExistSectionLearningDbValidate()
    sectionId: string

    section?: LearnSection

    @Field(_type => String, { nullable: false })
    @IsExistLessonLearningDbValidate()
    lessonIds: string

    lessons?: LearnLesson[]
}