import { Field, Float, ObjectType } from "@nestjs/graphql";
import {
    BaseEntity,
    Column, CreateDateColumn, DeleteDateColumn,
    Entity, Generated, JoinTable, ManyToMany,
    PrimaryGeneratedColumn, UpdateDateColumn,
} from "typeorm";
import { DocumentWiki, OfficeOrgChart, VersionWiki } from "@models/entities";
import { ActiveStatus } from "@common/enum.common";
import { BRIDGE_TABLE_DB_OBJ } from "@common/db/bridge-table.db";


@ObjectType()
@Entity("office-document-tag")
export class TagDocument extends BaseEntity {
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
    @JoinTable(BRIDGE_TABLE_DB_OBJ.DOCUMENT_TAG_ORG_CHART)
    orgCharts: OfficeOrgChart[]

    @ManyToMany(() => DocumentWiki, (ob) => ob.tags)
    @JoinTable(BRIDGE_TABLE_DB_OBJ.WIKI_DOCUMENT_TAG)
    wikis: DocumentWiki[] 
    
    @ManyToMany(() => VersionWiki, (ob) => ob.tags)
    @JoinTable(BRIDGE_TABLE_DB_OBJ.WIKI_VERSION_DOCUMENT_TAG)
    wikiVersions: VersionWiki[]
}