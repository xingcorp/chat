import { Field, Int, Float, ObjectType, registerEnumType } from "@nestjs/graphql";
import { RandomHelper } from "src/common/random";
import {
    AfterInsert,
    BaseEntity,
    BeforeInsert,
    BeforeUpdate,
    Column,
    CreateDateColumn,
    DeleteDateColumn,
    Entity,
    Generated, JoinTable,
    ManyToMany, OneToMany,
    PrimaryGeneratedColumn,
    Unique,
    UpdateDateColumn
} from "typeorm";
import { ObjectStatus } from "./profile.info.block";
import { OfficePayroll } from "@models/entities/payroll/payroll";
import { OfficeTaskProject } from "@models/entities/task/project.task";
import { OfficeLogs } from "@models/entities/logs/office-logs";
import { UserWorkProfileDetail } from "@models/entities/work-profile/detail.work-profile";
import { Asset } from "@models/entities/asset/asset";
import { CategoryAsset } from "@models/entities/asset/category.asset";
import { WarehouseAsset } from "@models/entities/asset/warehouse.asset";

export enum OrgChartType {
    Unknown = 'Unknown'
}

registerEnumType(OrgChartType, { name: 'OrgChartType' })

const NO_START_VALUE: number = 100000

@ObjectType()
@Entity("office-org-charts")
export class OfficeOrgChart extends BaseEntity {
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

    @Field(_type => OrgChartType)
    @Column({ nullable: false, type: 'enum', enum: OrgChartType, default: OrgChartType.Unknown })
    type: OrgChartType

    @Field(_type => ObjectStatus)
    @Column({ nullable: false, type: 'enum', enum: ObjectStatus, default: ObjectStatus.Active })
    status: ObjectStatus

    @Field(_type => String, { nullable: true })
    @Column({ nullable: true })
    note: string

    // @Field(_type => Float, { nullable: false })
    // @Column({ nullable: false })
    // order: number

    @Field(_type => String, { nullable: false })
    @Column({ nullable: false, default: 'root' })
    parentId: string

    @Field(_type => String, { nullable: false })
    @Column({ nullable: false })
    path: string

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

    @Field(_type => String, { nullable: true })
    @Column({ nullable: true })
    approverId: string

    @Field(_type => [OfficePayroll], {nullable: true})
    @ManyToMany(() => OfficePayroll, (ob) => ob.orgCharts)
    @JoinTable({
        name: "relation-org-chart-payroll",
    })
    payrolls: OfficePayroll[]

    @Field(_type => [OfficeTaskProject], { nullable: true })
    @OneToMany(() => OfficeTaskProject, (ob) => ob.rootOrg)
    projects: OfficeTaskProject[]

    @Field(_type => [OfficeLogs], {nullable: true})
    @ManyToMany(() => OfficeLogs, (ob) => ob.orgCharts)
    logs: OfficeLogs[]

    @Field(_type => UserWorkProfileDetail, { nullable: true })
    @OneToMany(() => UserWorkProfileDetail, (ob) => ob.department)
    workProfiles: UserWorkProfileDetail[]

    @Field(_type => [Asset], { nullable: true })
    @OneToMany(() => Asset, (ob) => ob.department)
    assets: Asset[]

    @Field(_type => [Asset], { nullable: true })
    @OneToMany(() => Asset, (ob) => ob.managementDepartment)
    assetsManagement: Asset[]

    @Field(_type => [CategoryAsset], { nullable: true })
    @OneToMany(() => CategoryAsset, (ob) => ob.orgChart)
    categoryAssets: CategoryAsset[]

    @Field(_type => [WarehouseAsset], { nullable: true })
    @OneToMany(() => WarehouseAsset, (ob) => ob.orgChart)
    warehouseAssets: WarehouseAsset[]

    @Field(_type => [Asset], { nullable: true })
    @OneToMany(() => Asset, (ob) => ob.assignedDepartment)
    assetsAssigned: Asset[]

    /**
     * Listeners
     * */

    @BeforeInsert()
    async beforeInsert() {
        this.id = RandomHelper.generateUUID()
        const lastestNo = await OfficeOrgChart.findOne({
            where: {},
            order: {
                no: "DESC"
            }
        })
        this.no = lastestNo ? lastestNo.no + 1 : 1
        if (!this.code) {
            this.code = 'P' + `${NO_START_VALUE + this.no}`.substr(1)
        }

        if (this.parentId) {
            const parent = await OfficeOrgChart.findOne({
                where: {
                    id: this.parentId
                }
            })
            this.path = `${parent.path}/${this.id}`
        } else {
            this.path = `/${this.id}`
        }
    }
}