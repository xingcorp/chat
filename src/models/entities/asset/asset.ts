import { Field, Float, ObjectType, registerEnumType } from "@nestjs/graphql";
import {
    BaseEntity, BeforeInsert,
    Column,
    CreateDateColumn,
    DeleteDateColumn,
    Entity, Generated,
    ManyToOne, OneToMany,
    PrimaryGeneratedColumn,
    UpdateDateColumn
} from "typeorm";
import { OfficeOrgChart } from "@models/entities/org.chart";
import { CategoryAsset } from "@models/entities/asset/category.asset";
import { AssignmentAsset } from "@models/entities/asset/assignment.asset";
import { AssetStatus } from "@enum/asset/asset.enum";
import { OfficeUser, WarehouseAsset } from "@models/entities";

registerEnumType(AssetStatus, { name: 'AssetStatus' })

@ObjectType()
@Entity("office-assets")
export class Asset extends BaseEntity {
    @Field(_type => String, { nullable: true })
    @PrimaryGeneratedColumn("uuid")
    id: string

    @Column({ nullable: true })
    @Generated('increment')
    no: number

    @Field(_type => String, { nullable: true })
    @Column({ nullable: true })
    code: string

    @Field(_type => String, { nullable: true })
    @Column({ nullable: true })
    name: string

    @Column('text', { nullable: true, array: true })
    imageIds: string[]

    @Field(_type => String, { nullable: true })
    @Column({ nullable: true })
    serial: string

    @Field(_type => String, { nullable: true })
    @Column({ nullable: true })
    description: string

    @Field(() => Float, { nullable: true })
    @Column({ type: 'bigint', nullable: true })
    price: string

    @Field(_type => Float, { nullable: true })
    @Column({ nullable: true })
    purchaseAt: Date

    @Field(_type => Number, { nullable: true })
    @Column({ nullable: true })
    monthlyDepreciation: number

    @Field(_type => Float, { nullable: true })
    @Column({ nullable: true })
    warrantyByMonth: number

    @Field(_type => Float, { nullable: true })
    @Column({ nullable: true })
    warrantyStartedAt: Date

    @Field(_type => Float, { nullable: true })
    @Column({ nullable: true })
    warrantyExpiredAt: Date

    @Field(_type => AssetStatus, { nullable: true })
    @Column({ nullable: true, type: 'enum', enum: AssetStatus })
    status: AssetStatus

    @Column('text', { nullable: true, array: true })
    attachmentIds: string[]

    @Field(_type => String, { nullable: true })
    @Column({ nullable: true })
    providerText: string

    @Field(_type => String, { nullable: true })
    @Column({ nullable: true })
    note: string

    @Field(_type => Float, { nullable: true })
    @CreateDateColumn()
    createdAt: Date

    @Field({ nullable: true })
    @Column({ nullable: true })
    createdBy: string

    @Field(_type => Float, { nullable: true })
    @UpdateDateColumn()
    updatedAt: Date

    @Field({ nullable: true })
    @Column({ nullable: true })
    updatedBy: string

    @DeleteDateColumn()
    deletedAt: Date

    @Field(_type => OfficeOrgChart, { nullable: true })
    @ManyToOne(() => OfficeOrgChart, (ob) => ob.assets, {
        eager: true
    })
    department: OfficeOrgChart

    @Field(_type => OfficeOrgChart, { nullable: true })
    @ManyToOne(() => OfficeOrgChart, (ob) => ob.assetsManagement, {
        eager: true
    })
    managementDepartment: OfficeOrgChart

    @Field(_type => OfficeUser, { nullable: true })
    @ManyToOne(() => OfficeUser, (ob) => ob.assetsManagement, {
        eager: true
    })
    managementUser: OfficeUser

    @Field(_type => CategoryAsset, { nullable: true })
    @ManyToOne(() => CategoryAsset, (ob) => ob.assets, {
        eager: true
    })
    category: CategoryAsset

    @Field(_type => WarehouseAsset, { nullable: true })
    @ManyToOne(() => WarehouseAsset, (ob) => ob.assets, {
        eager: true
    })
    warehouse: WarehouseAsset

    @Field(_type => OfficeOrgChart, { nullable: true })
    @ManyToOne(() => OfficeOrgChart, (ob) => ob.assetsAssigned, {
        eager: true
    })
    assignedDepartment: OfficeOrgChart

    @Field(_type => OfficeUser, { nullable: true })
    @ManyToOne(() => OfficeUser, (ob) => ob.assetsAssigned, {
        eager: true
    })
    assignedUser: OfficeUser

/*    @Field(_type => [AssignmentAsset], { nullable: true })
    @OneToMany(() => AssignmentAsset, (ob) => ob.asset, {
        eager: true
    })
    assignments: AssignmentAsset[]*/
}