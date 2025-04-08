import { Field, Float, ObjectType, registerEnumType } from "@nestjs/graphql"
import {
    BaseEntity, BeforeInsert,
    Column,
    CreateDateColumn,
    DeleteDateColumn,
    Entity, JoinTable, ManyToMany, OneToMany,
    PrimaryGeneratedColumn,
    UpdateDateColumn
} from "typeorm"
import { OfficeOrgChart, OfficeUserPaycheck } from "@models/entities";
import { stringNumberWithZeroLeading } from "@utils/string.utils";
import { ObjectStatus } from "@models/entities/profile.info.block";

registerEnumType(ObjectStatus, {name: 'ObjectStatus'})

@ObjectType()
@Entity("office-payroll")
export class OfficePayroll extends BaseEntity {
    @Field(_type => String)
    @PrimaryGeneratedColumn("uuid")
    id: string

    @Column({nullable: false})
    no: number

    @Field(_type => String, {nullable: true})
    @Column({nullable: false})
    code: string

    @Field(_type => String)
    @Column({nullable: false})
    name: string

    @Field(_type => ObjectStatus)
    @Column({nullable: false, type: 'enum', enum: ObjectStatus, default: ObjectStatus.Active})
    status: ObjectStatus

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

    @Field(_type => [OfficeUserPaycheck], {nullable: true})
    @OneToMany(() => OfficeUserPaycheck, (ob) => ob.payroll)
    paychecks: OfficeUserPaycheck[]

    @Field(_type => [OfficeOrgChart], {nullable: true})
    @ManyToMany(() => OfficeOrgChart, (ob) => ob.payrolls, {
        eager: true
    })
    orgCharts: OfficeOrgChart[]

    @BeforeInsert()
    async hello() {
        await this.createNo()

        this.createCode()
    }

    private async createNo() {
        const last = await OfficePayroll.findOne({
            where: {},
            order: {
                no: 'DESC'
            }
        })

        this.no = last ? last.no + 1 : 1
    }

    private createCode() {
        if (this.code) return

        this.code = `BL${stringNumberWithZeroLeading(this.no)}`
    }
}