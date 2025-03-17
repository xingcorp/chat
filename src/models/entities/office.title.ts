import { Field, Int, Float, ObjectType, registerEnumType } from "@nestjs/graphql";
import { __Type } from "graphql";
import {
    AfterInsert,
    BaseEntity,
    BeforeInsert,
    BeforeUpdate,
    Column,
    CreateDateColumn,
    DeleteDateColumn,
    Entity,
    Generated,
    OneToMany,
    PrimaryGeneratedColumn,
    Unique,
    UpdateDateColumn
} from "typeorm";
import { UserWorkProfileDetail } from "@models/entities/work-profile/detail.work-profile";

const NO_START_VALUE: number = 100000

@ObjectType()
@Entity("office-titles")
export class OfficeTitle extends BaseEntity {
    @Field(_type => String)
    @PrimaryGeneratedColumn("uuid")
    id: string

    @Field(_type => String)
    @Column({ nullable: false })
    name: string

    @Field(_type => Float)
    @Column({ nullable: false })
    // @Generated('increment')
    no: number

    @Field(_type => String, { nullable: true })
    @Column({ nullable: true })
    code: string

    // @Field(_type => ObjectStatus)
    // @Column({ nullable: false, type: 'enum', enum: ObjectStatus, default: ObjectStatus.Active })
    // status: ObjectStatus

    @Field(_type => String, { nullable: true })
    @Column({ nullable: true })
    note: string

    // @Field(_type => Float, { nullable: false })
    // @Column({ nullable: false })
    // order: number

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

    @Field(_type => UserWorkProfileDetail, { nullable: true })
    @OneToMany(() => UserWorkProfileDetail, (ob) => ob.title)
    workProfiles: UserWorkProfileDetail[]

    @BeforeInsert()
    async beforeInsert() {
        const lastestNo = await OfficeTitle.findOne({
            where: {},
            order: {
                no: "DESC"
            }
        })
        this.no = lastestNo ? lastestNo.no + 1 : 1
        this.code = 'CV' + `${NO_START_VALUE + this.no}`.substr(1)
    }
}