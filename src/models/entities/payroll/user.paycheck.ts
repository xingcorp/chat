import { Field, Float, Int, ObjectType, registerEnumType } from "@nestjs/graphql"
import {
    BaseEntity, BeforeInsert,
    Column,
    CreateDateColumn,
    DeleteDateColumn,
    Entity, ManyToOne,
    PrimaryGeneratedColumn,
    UpdateDateColumn
} from "typeorm"
import { OfficeOrgChart, OfficePayroll, OfficeUser, UserDepartment } from "@models/entities";
import { stringNumberWithZeroLeading } from "@utils/string.utils";
import { PaycheckStatus } from "@enum/payroll/paycheck.enum";

registerEnumType(PaycheckStatus, {name: 'PaycheckStatus'})

@ObjectType()
@Entity("office-user-paycheck")
export class OfficeUserPaycheck extends BaseEntity {
    @Field(_type => String)
    @PrimaryGeneratedColumn("uuid")
    id: string

    @Field(_type => String, {nullable: true})
    @Column({nullable: true})
    no: number

    @Field(_type => String, {nullable: true})
    @Column({nullable: true})
    code: string

    @Field(_type => String, {nullable: true})
    @Column({nullable: true})
    name: string

    @Field(_type => Int, {nullable: true})
    @Column({nullable: true})
    month: number

    @Field(_type => Int, {nullable: true})
    @Column({nullable: true})
    year: number

    // @Field(_type => Float, {nullable: true})
    @Column('text', {nullable: true})
    wage: string

    @Field(_type => Boolean, {defaultValue: false, nullable: true})
    @Column({nullable: true, default: false})
    encode: boolean

    @Column('text', { array: true, nullable: true })
    metadata: string[]

    @Field(_type => PaycheckStatus, {nullable: true})
    @Column({nullable: true, type: 'enum', enum: PaycheckStatus, default: PaycheckStatus.Done})
    status: PaycheckStatus

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

    @Field(_type => OfficeUser, { nullable: true })
    @ManyToOne(() => OfficeUser, (ob) => ob.paychecks, {
        eager: true
    })
    user: OfficeUser

    @Field(_type => OfficePayroll, { nullable: true })
    @ManyToOne(() => OfficePayroll, (ob) => ob.paychecks, {
        eager: true
    })
    payroll: OfficePayroll

    @BeforeInsert()
    async hello() {
        await this.createNo()

        await this.createCode()
    }

    private async createNo() {
        const last = await OfficeUserPaycheck.findOne({
            where: {},
            order: {
                no: 'DESC'
            }
        })

        this.no = last ? last.no + 1 : 1
    }

    private async createCode() {
        if (this.code) return

        const department = await UserDepartment.findOneBy({userId: this.user.id})
        const orgChart = department ? await OfficeOrgChart.findOneBy({id: department.departmentId}) : null

        this.code = `PL${orgChart?.code ?? ''}${stringNumberWithZeroLeading(this.no)}`
    }
}