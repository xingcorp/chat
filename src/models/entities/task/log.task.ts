import { Field, Float, ObjectType, registerEnumType } from "@nestjs/graphql";
import {
    BaseEntity,
    Column, CreateDateColumn, DeleteDateColumn,
    Entity, ManyToOne,
    PrimaryGeneratedColumn, UpdateDateColumn,
} from "typeorm";
import { TaskAction, TaskLogType, TaskPriority, TaskStatus, TaskTypeEnum } from "@enum/task/task.enum";
import { OfficeTask, OfficeUser } from "@models/entities";
import GraphQLJSON from "graphql-type-json";
import { OfficeAttachmentType } from "../../../arguments/logs/office-logs.args";

registerEnumType(TaskStatus, { name: 'TaskStatus' })
registerEnumType(TaskPriority, { name: 'TaskPriority' })
registerEnumType(TaskLogType, { name: 'TaskLogType' })
registerEnumType(TaskAction, { name: 'TaskAction' })


@ObjectType()
export class LogData {
    @Field(_type => TaskAction, { nullable: true })
    action: TaskAction

    @Field(_type => Float, { nullable: true })
    actionAt: number

    @Field(_type => String, { nullable: true })
    field: string

    @Field(_type => GraphQLJSON, { nullable: true })
    oldValue: string

    @Field(_type => GraphQLJSON, { nullable: true })
    newValue: string

    @Field(_type => TaskTypeEnum, { nullable: true })
    taskType: TaskTypeEnum

    @Field(_type => String, { nullable: true })
    note: string
}

@ObjectType()
@Entity("office-task-logs")
export class OfficeTaskLog extends BaseEntity {
    @Field(_type => String)
    @PrimaryGeneratedColumn("uuid")
    id: string

    @Field(_type => String, { nullable: true, description: "noi dung comment" })
    @Column({nullable: true})
    description: string

    @Field(_type => [OfficeAttachmentType], { nullable: true })
    @Column({
        type: "text",
        nullable: true,
        transformer: {
            to(value: any): string {
                return value
            },
            from(value: string): any {
                return JSON.parse(value);
            },
        },
    })
    objectType: string

    @Column('text', { nullable: true, array: true })
    objectIds: string[]

    // @Field(_type => GraphQLJSON, { nullable: true })
    @Field(_type => [LogData], { nullable: true })
    @Column({
        type: "json",
        nullable: true,
        transformer: {
            to(value: any): string {
                return value
            },
            from(value: string): any {
                return JSON.parse(value);
            },
        },
    })
    logs: string

    @Field(_type => TaskLogType)
    @Column({ nullable: false, type: 'enum', enum: TaskLogType, default: TaskLogType.History })
    type: TaskLogType

    @Column({nullable: true})
    note: string

    @Field(_type => OfficeUser, { nullable: true })
    @ManyToOne(() => OfficeUser, (ob) => ob.tasksLog, {
        eager: true
    })
    creator: OfficeUser

    @Field(_type => OfficeTask, {nullable: true})
    @ManyToOne(() => OfficeTask, (ob) => ob.logs, {
        eager: true
    })
    task: OfficeTask

    @Field(_type => Float)
    @CreateDateColumn()
    createdAt: Date

    @Field({ nullable: true })
    @Column({ nullable: true })
    createdBy: string

    @Field(_type => Float)
    @UpdateDateColumn()
    updatedAt: Date

    @Field({ nullable: true })
    @Column({ nullable: true })
    updatedBy: string

    @DeleteDateColumn()
    deletedAt: Date
}