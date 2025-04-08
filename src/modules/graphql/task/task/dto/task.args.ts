import { Field, Float, InputType, Int, ObjectType, OmitType, PartialType, registerEnumType } from "@nestjs/graphql";
import {
    TaskComplete,
    TaskPriority,
    TaskQuickSearchEnum,
    TaskSpeciesEnum,
    TaskStatus,
    TaskTypeEnum
} from "@enum/task/task.enum";
import { IsGreaterThanOrEqual } from "@decorators/validation/utils/is-greater-than-or-equal.validate";
import { ValidateIf, ValidateNested } from "class-validator";
import { DatePeriod } from "@common/args.common";
import { CommonListFilterPaginate, OnlyFilterKeywordWithNullPaginateArgs } from "@modules/graphql/common/common.args";
import { IsUndefinedValidate } from "@decorators/validation/utils/is-undefined.validate";
import { CustomIntOrAIntScalar } from "@helpers/scalar/graphql/int-or-array-of-int.graphql.scalar";
import { CloneDatePeriodEnum } from "@enum/clone/date.clone.enum";
import { OfficeFilter } from "@models/entities";
import { Expose, Transform, Type } from "class-transformer";
import {
    IsCanUpdateTaskFilterDbValidate
} from "@decorators/validation/db/filter/task/is-can-update.task.filter.db.validate";
import { OfficeTask } from "@models/entities";
import { IsExistTaskDbValidate } from "@decorators/validation/db/task/is-exist.task.db.validate";
import {
    IsNameNotExistTaskFilterDbValidate
} from "@decorators/validation/db/filter/task/is-name-not-exist.task.filter.db.validate";
import { IsGreaterThan } from "@decorators/validation/utils/is-greater-than.validate";
import { DayOfWeek } from "@common/constant.common";

registerEnumType(TaskComplete, { name: 'TaskComplete' })
registerEnumType(TaskQuickSearchEnum, { name: 'TaskQuickSearchEnum' })
registerEnumType(TaskSpeciesEnum, { name: 'TaskSpeciesEnum' })

@ObjectType()
@InputType()
export class CustomDayTaskReportConfigInput {
    @Field(() => Int, { nullable: true })
    month: number

    @Field(() => [Int], { nullable: true })
    days: number[]
}

@InputType()
export class TaskReportConfigCreateInput {
    @Field(_type => CloneDatePeriodEnum, { nullable: false, defaultValue: CloneDatePeriodEnum.Now })
    periodType: CloneDatePeriodEnum

    //Daily/Weekly/Monthly
    @Field(() => CustomIntOrAIntScalar, { nullable: true })
    @Transform(({ value }) => Array.isArray(value) ? value : [value])
    startTimeIn: number[]

    @Field(() => Float, { nullable: true, defaultValue: 7 })
    timeZone: number

    @Field(() => [DayOfWeek], { nullable: true })
    weekDays: DayOfWeek[]

    @Field(() => [Int], { nullable: true })
    monthDays: number[]

    @Field(_type => Float, { nullable: true })
    startAt: Date

    @Field(_type => Float, { nullable: true })
    @ValidateIf(o => o.endAt && o.startAt)
    @IsGreaterThan('startAt', {
        message: 'WrongEndDatePeriod'
    })
    endAt: Date

    @Field(() => Float, { nullable: true })
    workDays: number

    @Field(() => [CustomDayTaskReportConfigInput], { nullable: true })
    customDays: CustomDayTaskReportConfigInput[]
}

@InputType()
export class TaskCreateInput {
    @Field(_type => TaskTypeEnum, { nullable: true })
    taskType: TaskTypeEnum

    @Field(_type => String, { nullable: false })
    title: string

    @Field(_type => String, { nullable: true })
    description: string

    @Field(_type => [String], { nullable: true, description: 'list id file dinh kem' })
    attachmentIds: string[]

    @Field(_type => [String], { nullable: true })
    @ValidateIf(o => o.linkTaskIds)
    @IsExistTaskDbValidate()
    linkTaskIds: string[]

    linkTasks?: OfficeTask[]

    @Field(_type => String, { nullable: true })
    reporterId: string

    @Field(_type => String, { nullable: true })
    @ValidateIf(o => o.assignedIds)
    @IsUndefinedValidate()
    assignedId: string

    @Field(_type => [String], { nullable: true })
    @ValidateIf(o => [TaskTypeEnum.Task, TaskTypeEnum.Report].includes(o.taskType))
    @IsUndefinedValidate()
    assignedIds: string[]

    @Field(_type => [String], { nullable: true })
    watcherIds: string[]

    @Field(_type => TaskStatus, { nullable: true, description: 'Trang thai' })
    status: TaskStatus

    @Field(_type => TaskPriority, { nullable: true, description: 'Do uu tien' })
    priority: TaskPriority

    @Field(_type => Float, { nullable: true })
    startTime: number;

    @Field(_type => Float, { nullable: true })
    @ValidateIf(o => o.startTime && o.finishTime)
    @IsGreaterThanOrEqual('startTime', {
        message: 'WrongDatePeriod'
    })
    finishTime: number;

    @Field(_type => TaskReportConfigCreateInput, { nullable: true })
    @ValidateNested({ each: true })
    @Type(() => TaskReportConfigCreateInput)
    config: TaskReportConfigCreateInput
}

@InputType()
export class TaskUpdateInput extends PartialType(OmitType(TaskCreateInput, ['taskType'])) {
    @Field(_type => String, { nullable: false })
    id: string
}

@InputType()
export class TaskStatusUpdateInput {
    @Field(_type => String, { nullable: false })
    @IsExistTaskDbValidate()
    taskId: string

    task?: OfficeTask

    @Field(_type => TaskStatus, { nullable: false, description: 'Trang thai' })
    status: TaskStatus

    @Field(_type => String, { nullable: true })
    note: string
}

@InputType()
export class TaskListFilter extends CommonListFilterPaginate {
    @Field(_type => TaskSpeciesEnum, { nullable: true, defaultValue: TaskSpeciesEnum.REPORT })
    species?: TaskSpeciesEnum

    @Field({ nullable: true })
    keyword?: string

    @Field(_type => [TaskQuickSearchEnum], { nullable: true })
    quickSearches?: TaskQuickSearchEnum[]

    @Field(_type => [String], { nullable: true })
    creatorIds?: string[]

    @Field(_type => [String], { nullable: true })
    reportedIds?: string[]

    @Field(_type => [String], { nullable: true })
    assignedIds?: string[]

    @Field(_type => [String], { nullable: true })
    watchersIds?: string[]

    @Field(_type => [TaskStatus], { nullable: true, description: 'Trang thai' })
    status?: TaskStatus[]

    @Field(_type => [TaskPriority], { nullable: true, description: 'Do uu tien' })
    priority?: TaskPriority[]

    @Field(_type => DatePeriod, { nullable: true })
    startTime?: DatePeriod

    @Field(_type => DatePeriod, { nullable: true })
    finishTime?: DatePeriod

    @Field(_type => Boolean, { nullable: true, description: 'Null to get all' })
    isLate?: boolean

    @Field(_type => TaskComplete, { nullable: true })
    complete?: TaskComplete

    @Field(_type => [TaskTypeEnum], { nullable: true })
    taskTypes?: TaskTypeEnum[]

    @Field(_type => [String], { nullable: true })
    templateTaskIds?: string[]

    @Field(_type => String, { nullable: true })
    excludeLinkedTaskId: string
}

@InputType()
export class TaskFilterSave extends PartialType(OmitType(TaskListFilter, ['size', 'page'])) {
}

@InputType()
export class TaskFilterCreateInput {
    @Field(_type => TaskSpeciesEnum, { nullable: true, defaultValue: TaskSpeciesEnum.REPORT })
    species?: TaskSpeciesEnum

    @Field({ nullable: true })
    @IsNameNotExistTaskFilterDbValidate()
    name: string

    /*@Field({ nullable: true })
    order: number*/

    @Field(() => TaskFilterSave, { nullable: true })
    filter: TaskFilterSave
}

@InputType()
export class TaskFilterUpdateInput extends TaskFilterCreateInput {
    @Field(_type => String, { nullable: true })
    @IsCanUpdateTaskFilterDbValidate()
    taskFilterId: string

    taskFilter?: OfficeFilter

    @Expose()
    @Transform(({ obj }) => obj.taskFilterId)
    IsNameNotExistTaskFilterDbValidate_filterId?: string = null
}

@InputType()
export class TaskFilterList {
    @Field(_type => TaskSpeciesEnum, { nullable: true, defaultValue: TaskSpeciesEnum.REPORT })
    species?: TaskSpeciesEnum

    @Field({ nullable: true })
    page?: number

    @Field({ nullable: true })
    size?: number

    @Field({ nullable: true })
    keyword?: string
}

@InputType()
export class TaskReportConfigList extends OnlyFilterKeywordWithNullPaginateArgs { }