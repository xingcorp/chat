import { Field, Float, InputType, Int } from "@nestjs/graphql";
import { LearnSection, LearnCourse, LearnProject, OfficeUser } from "@models/entities";
import { ValidateIf, ValidateNested } from "class-validator";
import { Type } from "class-transformer";
import { DefaultFilterInput } from "@common/args.common";
import {
    IsExistSectionLearningDbValidate
} from "@decorators/validation/db/learning/section/is-exist.section.learning.db.validate";
import { IsGreaterThan } from "@decorators/validation/utils/is-greater-than.validate";
import { CourseJoinTypeEnum, CourseProposerTypeEnum, CourseStatusEnum, CourseTrainTypeEnum } from "@enum/learning/learning.enum";
import {
    IsExistProjectLearningDbValidate
} from "@decorators/validation/db/learning/project/is-exist.project.learning.db.validate";
import { IsExistAndGetUserDbValidate } from "@decorators/validation/db/user/is-exist-and-get.user.db.validate";
import { LearningSectionUpsertInput } from "../section/dto/section.learning.arg";
import { IsExistCourseLearningDbValidate } from "@decorators/validation/db/learning/course/is-exist.course.learning.db.validate";
import { IsCodeExistCourseLearningDbValidate } from "@decorators/validation/db/learning/course/is-exist.code.course.learning.db.validate";
import { DayOfWeek } from "@common/constant.common";
import { IsNameExistCourseLearningDbValidate } from "@decorators/validation/db/learning/course/is-name-exist.course.learning.db.validate";
import { IsExistAddressLearningDbValidate } from "@decorators/validation/db/learning/address/is-exist.address.learning.db.validate";
@InputType()
export class LearningCourseCreateInput {
    @Field(_type => String, { nullable: true })
    @ValidateIf(o => o.name)
    @IsNameExistCourseLearningDbValidate()
    name: string

    @Field(_type => String, { nullable: true })
    @ValidateIf(o => o.code)
    @IsCodeExistCourseLearningDbValidate()
    code: string

    @Field(_type => CourseStatusEnum, { nullable: true })
    status: CourseStatusEnum

    @Field(_type => Float, { nullable: true, description: 'Ngày bắt đầu khóa học' })
    startClassAt: Date

    @Field(_type => Float, { nullable: true, description: 'Ngày kết thúc khóa học' })
    closeClassAt: Date

    @Field(_type => String, { nullable: true, description: 'Thời gian lớp mở' })
    timeStartAt: string

    @Field(_type => String, { nullable: true, description: 'Thời gian lớp đóng' })
    timeCloseAt: string

    @Field(_type => CourseJoinTypeEnum, { nullable: true })
    joinType: CourseJoinTypeEnum

    @Field(_type => Float, { nullable: true, description: 'Ngày bắt đầu đăng ký' })
    enrollStartAt: Date

    @Field(_type => Float, { nullable: true, description: 'Ngày kết thúc đăng ký' })
    @ValidateIf(o => o.enrollEndAt && o.enrollStartAt)
    @IsGreaterThan('enrollStartAt', {
        message: 'WrongEndDatePeriod'
    })
    enrollEndAt: Date

    @Field(_type => Int, { nullable: true })
    totalStudent: number

    @Field(_type => Float, { nullable: true, description: 'Số giờ đào tạo' })
    totalTimeTraining: number

    @Field(_type => Int, { nullable: true, description: 'Thời hạn hoàn thành lớp học' })
    estimateDeadline: number

    @Field(_type => [DayOfWeek], { nullable: true, description: 'Lịch học' })
    pickedDays: DayOfWeek[]

    @Field(_type => [CourseTrainTypeEnum], { nullable: true })
    trainingTypes: CourseTrainTypeEnum[]

    @Field(_type => [String], { nullable: true })
    @ValidateIf(o => o.trainingAddressIds)
    @IsExistAddressLearningDbValidate()
    trainingAddressIds: string[]

    @Field(_type => String, { nullable: true })
    @ValidateIf(o => o.projectId)
    @IsExistProjectLearningDbValidate()
    projectId: string

    project?: LearnProject

    @Field(_type => String, { nullable: true })
    @ValidateIf(o => o.teacherId)
    @IsExistAndGetUserDbValidate()
    teacherId: string

    teacher?: OfficeUser

    @Field(_type => CourseProposerTypeEnum, { nullable: true })
    teacherType: CourseProposerTypeEnum

    @Field(_type => String, { nullable: true })
    @ValidateIf(o => o.proposerId)
    @IsExistAndGetUserDbValidate()
    proposerId: string

    proposer?: OfficeUser

    @Field(_type => [String], { nullable: true })
    @ValidateIf(o => o.studentIds && o.studentIds.length)
    @IsExistAndGetUserDbValidate()
    studentIds: string[]

    students?: OfficeUser[]

    @Field(_type => [LearningSectionUpsertInput], { nullable: true })
    @ValidateIf(o => o.sections && o.sections.length)
    @ValidateNested({ each: true })
    @Type(() => LearningSectionUpsertInput)
    sections: LearningSectionUpsertInput[]
}

@InputType()
export class LearningCourseUpdateInput extends LearningCourseCreateInput {
    @Field(_type => String, { nullable: true })
    @ValidateIf(o => o.courseId)
    @IsExistCourseLearningDbValidate()
    courseId: string

    course?: LearnCourse
}

@InputType()
export class LearningCourseUpsertInput extends LearningCourseCreateInput {
    @Field(_type => String, { nullable: true })
    @ValidateIf(o => o.courseId)
    @IsExistCourseLearningDbValidate()
    courseId: string

    course?: LearnCourse
}

@InputType()
export class LearningCourseFilterInput extends DefaultFilterInput { }

@InputType()
export class LearningCourseReOrderSectionInput {
    @Field(_type => String, { nullable: false })
    @IsExistCourseLearningDbValidate()
    id: string

    course?: LearnCourse

    @Field(_type => String, { nullable: false })
    @IsExistSectionLearningDbValidate()
    sectionIds: string

    sections?: LearnSection[]
}