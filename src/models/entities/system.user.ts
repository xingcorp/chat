import { Field, Float, Int, ObjectType } from "@nestjs/graphql"
import {
    BaseEntity,
    Column,
    CreateDateColumn,
    DeleteDateColumn,
    Entity,
    Generated, JoinColumn,
    OneToMany, OneToOne,
    PrimaryGeneratedColumn,
    UpdateDateColumn
} from "typeorm"
import { ObjectStatus } from "./profile.info.block"
import { OfficeLogs } from "@models/entities/logs/office-logs";
import { OfficeUser } from "@models/entities/profile.user";

@ObjectType()
@Entity("office-sys-users")
export class OfficeSysUser extends BaseEntity {
    @Field(_type => String)
    @PrimaryGeneratedColumn("uuid")
    id: string

    @Field(_type => Float)
    @Column({ nullable: false })
    @Generated('increment')
    no: number

    @Field(_type => String, { nullable: false }) //Họ tên
    @Column({ nullable: false })
    fullname: string

    @Field(_type => String, { nullable: true }) //Mã nhân viên
    @Column({ nullable: true })
    code: string

    @Field(_type => String, { nullable: true }) //Số điện thoại
    @Column({ nullable: true })
    phone: string

    @Field(_type => String, { nullable: true }) //Email công ty
    @Column({ nullable: true })
    email: string

    @Column({ nullable: false })
    iamUserId: string

    @Column({ nullable: false })
    businessRoleId: string

    @Field(_type => ObjectStatus)
    @Column({ nullable: false, type: 'enum', enum: ObjectStatus, default: ObjectStatus.Active })
    status: ObjectStatus

    @Field(() => [String], { nullable: true })
    @Column('text', { nullable: true, array: true })
    orgChartIds: string[]

    @Field(_type => [OfficeLogs], { nullable: true })
    @OneToMany(() => OfficeLogs, (ob) => ob.adminCreator)
    logs: OfficeLogs[]

    @OneToOne(() => OfficeUser)
    @JoinColumn()
    user: OfficeUser

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