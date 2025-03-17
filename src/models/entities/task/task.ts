import { Field, Float, ObjectType, registerEnumType } from "@nestjs/graphql";
import {
    BaseEntity, BeforeInsert,
    Column, CreateDateColumn, DeleteDateColumn,
    Entity, JoinTable, ManyToMany, ManyToOne, MoreThanOrEqual, OneToMany,
    PrimaryGeneratedColumn, UpdateDateColumn,
} from "typeorm";
import { TaskKindEnum, TaskPriority, TaskStatus, TaskTypeEnum } from "@enum/task/task.enum";
import { OfficeTaskLog, OfficeTaskProject, OfficeUser } from "@models/entities";
import {
    datetimeOfLocalDayToString,
    datetimeStartOfLocalDay
} from "@utils/datetime.utils";
import { stringNumberWithZeroLeading } from "@utils/string.utils";
import { BRIDGE_TABLE_DB } from "@common/db/bridge-table.db";

registerEnumType(TaskStatus, {name: 'TaskStatus'})
registerEnumType(TaskPriority, {name: 'TaskPriority'})
registerEnumType(TaskTypeEnum, {name: 'TaskTypeEnum'})
registerEnumType(TaskKindEnum, {name: 'TaskKindEnum'})

export const TASK_WATCHER_BRIDGE_TABLE = "office-user-watcher-tasks"

@ObjectType()
@Entity("office-tasks")
export class OfficeTask extends BaseEntity {
    @Field(_type => String)
    @PrimaryGeneratedColumn("uuid")
    id: string

    @Field(_type => Float)
    @Column({nullable: false})
    no: number

    @Field(_type => String, {nullable: true})
    @Column({nullable: true})
    keyPostfix: string

    @Field(_type => TaskTypeEnum, {nullable: true, defaultValue: TaskTypeEnum.Task})
    @Column({nullable: true, default: TaskTypeEnum.Task})
    taskType: TaskTypeEnum

    @Field(_type => TaskKindEnum, {nullable: true})
    @Column({nullable: true})
    taskKind: TaskKindEnum

    @Field(_type => String, {nullable: true})
    @Column({nullable: true})
    title: string

    @Field(_type => String, {nullable: true})
    @Column({nullable: true})
    description: string

    @Field(_type => Float, {nullable: true})
    @Column({type: 'timestamptz', nullable: true})
    startTime: Date

    @Field(_type => Float, {nullable: true})
    @Column({type: 'timestamptz', nullable: true})
    finishTime: Date

    @Field(_type => Float, {nullable: true})
    @Column({type: 'timestamptz', nullable: true})
    doneAt: Date

    @Field(_type => TaskStatus, {nullable: true, defaultValue: TaskStatus.Todo})
    @Column({nullable: true, type: 'enum', enum: TaskStatus, default: TaskStatus.Todo})
    status: TaskStatus

    @Field(_type => TaskPriority, {nullable: true, defaultValue: TaskPriority.Medium})
    @Column({nullable: true, type: 'enum', enum: TaskPriority, default: TaskPriority.Medium})
    priority: TaskPriority

    @ManyToOne(() => OfficeTaskProject, (ob) => ob.tasks, {
        eager: true
    })
    project: OfficeTaskProject

    @Column('text', {nullable: true, array: true})
    attachmentIds: string[]

    @Field(() => [String], {nullable: true})
    @Column('text', {nullable: true, array: true})
    attachmentUrls: string[]

    @ManyToOne(() => OfficeUser, {
        eager: true
    })
    creator: OfficeUser

    @ManyToOne(() => OfficeUser, (ob) => ob.tasksCreated)
    reporter: OfficeUser

    @ManyToOne(() => OfficeUser, (ob) => ob.tasksAssigned)
    assigned: OfficeUser

    @ManyToMany(() => OfficeUser, (ob) => ob.taskWatchers)
    @JoinTable({
        name: TASK_WATCHER_BRIDGE_TABLE,
    })
    watchers: OfficeUser[]

    @ManyToMany(() => OfficeUser)
    @JoinTable({
        name: BRIDGE_TABLE_DB.TASK_CONFIG_ASSIGNEES,
    })
    assignees: OfficeUser[]

    @ManyToMany(() => OfficeTask)
    @JoinTable({
        name: BRIDGE_TABLE_DB.TASK_LINK_TASK,
    })
    linkTasks: OfficeTask[]

    @OneToMany(() => OfficeTaskLog, (ob) => ob.task)
    logs: OfficeTaskLog[]

    @ManyToOne(() => OfficeTask, (ob) => ob.clonesTask)
    templateTask: OfficeTask

    @OneToMany(() => OfficeTask, (ob) => ob.templateTask)
    clonesTask: OfficeTask[]

    @ManyToOne(() => OfficeTask, (ob) => ob.childrenTask)
    parentTask: OfficeTask

    @OneToMany(() => OfficeTask, (ob) => ob.parentTask)
    childrenTask: OfficeTask[]

    @Field(_type => Float)
    @CreateDateColumn()
    createdAt: Date

    @Field({nullable: true})
    @Column({nullable: true})
    createdBy: string

    @Field(_type => Float)
    @UpdateDateColumn()
    updatedAt: Date

    @Field({nullable: true})
    @Column({nullable: true})
    updatedBy: string

    @DeleteDateColumn()
    deletedAt: Date

    @BeforeInsert()
    async genData() {
        await this.genNo()
        await this.genKey()
    }

    private async genNo() {
        const count = await OfficeTask.countBy({
            project: {
                id: this.project.id
            },
        })

        this.no = count + 1
    }

    /*TODO: seed data*/
    private async genKey() {
        if (this.keyPostfix) return
        const project = await OfficeTaskProject.findOne({
            relations: ['rootOrg'],
            where: {
                id: this.project.id
            }
        })

        if (project && project.rootOrg.id !== process.env.K_ORG_ID && this.no) {
            this.keyPostfix = this.no.toString()
            return
        }

        const count = await OfficeTask.countBy({
            project: {
                id: this.project.id
            },
            createdAt: MoreThanOrEqual(datetimeStartOfLocalDay())
        })
        // this.keyPostfix = `${datetimeGetFormat('DD/MM/YYYY', (getDateLocal(new Date())).toString()).replaceAll('/', '')}-${stringNumberWithZeroLeading(count + 1)}`
        this.keyPostfix = `${datetimeOfLocalDayToString('DDMMYYYY')}-${stringNumberWithZeroLeading(count + 1)}`
    }

    /*Method*/
    public isReportChild() {
        return this.taskKind === TaskKindEnum.ReportChild
    }
}