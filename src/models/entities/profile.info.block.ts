import { Field, Int, Float, ObjectType, registerEnumType } from "@nestjs/graphql";
import { __Type } from "graphql";
import { AfterInsert, BaseEntity, BeforeInsert, BeforeUpdate, Column, CreateDateColumn, DeleteDateColumn, Entity, Generated, PrimaryGeneratedColumn, Unique, UpdateDateColumn } from "typeorm";
import GraphQLJSON from "graphql-type-json"
import { stringNumberWithZeroLeading } from "@utils/string.utils";
import { OfficeBlockType } from "@enum/block/block.enum";

export enum ObjectStatus {
    Active = 'Active',
    Inactive = 'Inactive'
}

registerEnumType(ObjectStatus, { name: 'ObjectStatus' })

const NO_START_VALUE: number = 100000

@ObjectType()
@Entity("office-info-blocks")
// @Unique(["code"])
export class InfoBlock extends BaseEntity {
    @Field(_type => String)
    @PrimaryGeneratedColumn("uuid")
    id: string

    @Column({ nullable: false, default: OfficeBlockType.User })
    relationType: OfficeBlockType

    @Column({ nullable: true })
    relationId: string

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

    @Field(_type => ObjectStatus)
    @Column({ nullable: false, type: 'enum', enum: ObjectStatus, default: ObjectStatus.Active })
    status: ObjectStatus

    @Field(_type => String, { nullable: true })
    @Column({ nullable: true })
    note: string

    @Field(_type => Float, { nullable: false })
    @Column({ nullable: false })
    order: number

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

    @Field(() => GraphQLJSON, { nullable: true, defaultValue: null })
    officeUserExtraData: JSON

    // @AfterInsert()
    // async afterInsert() {
    //     this.code = `block_${this.name.trim().normalize('NFD').replace(/[\u0300-\u036f]/g, '').replace(/[^A-Z0-9]+/ig, "_").toLowerCase()}_${this.no}`
    //     this.save()
    // }

    @BeforeInsert()
    async beforeInsert() {
        switch (this.relationType) {
            case OfficeBlockType.Payroll:
                await this.beforeInsertBlockPayroll()
                return
            case OfficeBlockType.WorkProfile:
                await this.beforeInsertBlockWorkProfile()
                return
            case OfficeBlockType.User:
            default:
                await this.beforeInsertBlockUser()
                return
        }
    }

    async beforeInsertBlockUser() {
        const latestNo = await InfoBlock.findOne({
            where: {
                relationType: OfficeBlockType.User
            },
            order: {
                no: "DESC"
            }
        })
        this.no = latestNo ? latestNo.no + 1 : 1

        const latestRecord = await InfoBlock.findOne({
            where: {
                relationType: OfficeBlockType.User
            },
            order: {
                order: "DESC"
            }
        })
        this.order = latestRecord ? latestRecord.order + 1 : 1

        // this.code = `block_${this.name.trim().normalize('NFD').replace(/[\u0300-\u036f]/g, '').replace(/[^A-Z0-9]+/ig, "_").toLowerCase()}_${this.no}`
        this.code = 'KH' + `${NO_START_VALUE + this.no}`.substr(1)
    }

    async beforeInsertBlockPayroll() {
        const latestNo = await InfoBlock.findOne({
            where: {
                relationType: OfficeBlockType.Payroll,
            },
            order: {
                no: "DESC"
            }
        })
        this.no = latestNo ? latestNo.no + 1 : 1

        const latestRecord = await InfoBlock.findOne({
            where: {
                relationType: OfficeBlockType.Payroll,
                relationId: this.relationId
            },
            order: {
                order: "DESC"
            }
        })
        this.order = latestRecord ? latestRecord.order + 1 : 1

        /*gen code*/
        this.code = this.code ?? `KL${stringNumberWithZeroLeading(this.no)}`
    }

    private async beforeInsertBlockWorkProfile() {
        const latestNo = await InfoBlock.count({
            where: {
                relationType: OfficeBlockType.WorkProfile,
            }
        })
        this.no = latestNo + 1

        const latestRecord = await InfoBlock.count({
            where: {
                relationType: OfficeBlockType.WorkProfile,
                relationId: this.relationId
            }
        })
        this.order = latestRecord + 1

        this.code = `WP${stringNumberWithZeroLeading(this.no)}`
    }
}