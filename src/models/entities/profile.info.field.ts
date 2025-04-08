import { Field, Float, ObjectType, registerEnumType } from "@nestjs/graphql"
import { AfterInsert, BaseEntity, BeforeInsert, Column, CreateDateColumn, DeleteDateColumn, Entity, Generated, PrimaryGeneratedColumn, UpdateDateColumn } from "typeorm"
import { InfoBlock, ObjectStatus } from "./profile.info.block"
import GraphQLJSON from "graphql-type-json"
import { stringNumberWithZeroLeading } from "@utils/string.utils";
import { OfficeBlockType } from "@enum/block/block.enum";
import { LinkFieldType, LinkTableType } from "@enum/block/field.enum";

export enum DataType {
    Text = 'Text',
    Date = 'Date',
    List = 'List',
    Number = 'Number',
    Email = 'Email',
    Number_Limit_Length_10 = 'Number_Limit_Length_10',
    Table = 'Table',
    Text_Area = 'Text_Area',
    Text_Html = 'Text_Html',
}

registerEnumType(DataType, { name: 'DataType' })

const NO_START_VALUE: number = 100000

@ObjectType()
@Entity("office-info-fields")
// @Unique(["code"])
export class InfoField extends BaseEntity {
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

    @Field({ nullable: false, defaultValue: false })
    @Column({ nullable: false, default: false })
    required: boolean

    // @Field({ nullable: false, defaultValue: false })
    // @Column({ nullable: false, default: false })
    // displayInBrief: boolean

    @Field(_type => DataType)
    @Column({ nullable: false, type: 'enum', enum: DataType, default: DataType.Text })
    dataType: DataType

    @Field(_type => ObjectStatus)
    @Column({ nullable: false, type: 'enum', enum: ObjectStatus, default: ObjectStatus.Active })
    status: ObjectStatus

    @Field(() => [String], { nullable: true })
    @Column('text', { nullable: true, array: true })
    optionItems: string[]

    @Column({ nullable: false })
    blockId: string

    @Field(_type => String, { nullable: true })
    @Column({ nullable: true })
    note: string

    // @Field(_type => String, { nullable: true })
    // @Column({ nullable: true })
    // fieldLength: string

    @Field(_type => Float, { nullable: false })
    @Column({ nullable: false })
    order: number

    @Column({ nullable: true })
    linkTableType: LinkTableType

    @Column({ nullable: true })
    linkFieldType: LinkFieldType

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
    // afterInsert() {
    //     this.code = `field_${this.name.trim().normalize('NFD').replace(/[\u0300-\u036f]/g, '').replace(/[^A-Z0-9]+/ig, "_").toLowerCase()}_${this.no}`
    //     this.save()
    // }

    @BeforeInsert()
    async beforeInsert() {
        const latestRecord = await InfoField.count({
            where: {
                blockId: this.blockId
            }
        })
        this.order = this.order ?? latestRecord + 1

        const latestNo = await InfoField.count({withDeleted: true})
        this.no = latestNo + 1

        await this.genCode()
        this.no = latestNo + 1
    }

    async genCode() {
        const block = await InfoBlock.findOne({
            where: {
                id: this.blockId,
            }
        })

        switch (block?.relationType) {
            case OfficeBlockType.Payroll:
                this.beforeInsertPayrollField()
                return
            case OfficeBlockType.WorkProfile:
                this.beforeInsertWorkProfileField()
                return
            case OfficeBlockType.User:
            default:
                this.beforeInsertUserField()
                return
        }
    }

    private beforeInsertUserField() {
        // this.code = `field_${this.name.trim().normalize('NFD').replace(/[\u0300-\u036f]/g, '').replace(/[^A-Z0-9]+/ig, "_").toLowerCase()}_${this.no}`
        this.code = 'T' + `${NO_START_VALUE + this.no}`.substr(1)
    }

    private beforeInsertPayrollField() {
        this.code = this.code ?? `TL${stringNumberWithZeroLeading(this.no)}`
    }

    private beforeInsertWorkProfileField() {
        this.code = this.code ?? `WP${stringNumberWithZeroLeading(this.no)}`
    }
}