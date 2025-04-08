import { Field, Float, ObjectType } from "@nestjs/graphql";
import {
    BaseEntity, BeforeInsert,
    Column,
    CreateDateColumn,
    DeleteDateColumn,
    Entity,
    Generated, ManyToOne,
    OneToMany,
    PrimaryGeneratedColumn,
    UpdateDateColumn
} from "typeorm";
import { Asset } from "@models/entities/asset/asset";
import { OfficeOrgChart } from "@models/entities";
import { stringNumberWithZeroLeading } from "@utils/string.utils";


@ObjectType()
@Entity("office-asset-warehouse")
export class WarehouseAsset extends BaseEntity {
    @Field(_type => String)
    @PrimaryGeneratedColumn("uuid")
    id: string

    @Column({ nullable: true })
    @Generated('increment')
    no: number

    @Field(_type => String, { nullable: true })
    @Column({ nullable: true })
    code: string

    @Field(_type => String)
    @Column({ nullable: true })
    name: string

    @Field(_type => String, { nullable: true })
    @Column({ nullable: true })
    note: string

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

    @Field(_type => OfficeOrgChart, { nullable: true })
    @ManyToOne(() => OfficeOrgChart, (ob) => ob.warehouseAssets, {
        eager: true
    })
    orgChart: OfficeOrgChart

    @Field(_type => [Asset], { nullable: true })
    @OneToMany(() => Asset, (ob) => ob.warehouse)
    assets: Asset[]

    /*Listener*/
    @BeforeInsert()
    async genData() {
        await this.genCode()
    }

    private async genCode() {
        const count = await WarehouseAsset.count({withDeleted: true})

        this.code = `WA${stringNumberWithZeroLeading(count + 1)}`
    }
}