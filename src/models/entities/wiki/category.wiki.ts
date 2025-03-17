import { Field, Float, ObjectType } from "@nestjs/graphql";
import {
    BaseEntity,
    Column, CreateDateColumn, DeleteDateColumn,
    Entity, Generated, JoinTable, ManyToMany,
    PrimaryGeneratedColumn, UpdateDateColumn,
} from "typeorm";
import { DocumentWiki, OfficeOrgChart } from "@models/entities";
import { ActiveStatus } from "@common/enum.common";
import { BRIDGE_TABLE_DB_OBJ } from "@common/db/bridge-table.db";

@ObjectType()
@Entity("office-document-wiki-category")
export class CategoryWiki extends BaseEntity {
    @Field(_type => String)
    @PrimaryGeneratedColumn("uuid")
    id: string

    @Field(_type => Float)
    @Column({nullable: true})
    @Generated('increment')
    no: number

    @Field(_type => String)
    @Column({ nullable: false })
    name: string

    @Field(_type => ActiveStatus)
    @Column({ nullable: false, default: ActiveStatus.Active })
    status: ActiveStatus

    @Field(_type => Float, {nullable: true})
    @CreateDateColumn()
    createdAt: Date

    @Field({nullable: true})
    @Column({nullable: true})
    createdBy: string

    @Field(_type => Float, {nullable: true})
    @UpdateDateColumn()
    updatedAt: Date

    @Field({nullable: true})
    @Column({nullable: true})
    updatedBy: string

    @DeleteDateColumn()
    deletedAt: Date

    /*relation*/
    @ManyToMany(() => OfficeOrgChart)
    @JoinTable(BRIDGE_TABLE_DB_OBJ.WIKI_CATEGORY_ORG_CHART)
    orgCharts: OfficeOrgChart[]

    @ManyToMany(() => DocumentWiki, (ob) => ob.categories)
    @JoinTable(BRIDGE_TABLE_DB_OBJ.WIKI_CATEGORY)
    wikis: DocumentWiki[]
}