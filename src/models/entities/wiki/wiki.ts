import { Field, Float, ObjectType, registerEnumType } from "@nestjs/graphql";
import {
    BaseEntity, BeforeInsert,
    Column, CreateDateColumn, DeleteDateColumn,
    Entity, Generated, In, JoinColumn, JoinTable, ManyToMany, ManyToOne, OneToMany, OneToOne,
    PrimaryGeneratedColumn, UpdateDateColumn,
} from "typeorm";
import { DocumentFolder, OfficeOrgChart, OfficeUser, Viewer } from "@models/entities";
import { VersionWiki } from "@models/entities/wiki/version.wiki";
import { VersionWikiStatus, WikiImportant, WikiStatus } from "@enum/wiki/wiki.enum";
import { CategoryWiki } from "@models/entities/wiki/category.wiki";
import { TagDocument } from "@models/entities/document/tag.document";
import { BRIDGE_TABLE_DB_OBJ } from "@common/db/bridge-table.db";

registerEnumType(WikiStatus, { name: 'WikiStatus' })
registerEnumType(WikiImportant, { name: 'WikiImportant' })

@ObjectType()
@Entity("office-document-wikis")
export class DocumentWiki extends BaseEntity {
    @Field(_type => String)
    @PrimaryGeneratedColumn("uuid")
    id: string

    @Field(_type => Float)
    @Column({ nullable: true })
    @Generated('increment')
    no: number

    @Field({ nullable: true })
    @Column({ nullable: true })
    code: string

    @Field({ nullable: true })
    @Column({ nullable: true })
    name: string

    @Field({ nullable: true })
    @Column({ nullable: true, default: false })
    isPublic: boolean

    @Field(_type => WikiStatus, { nullable: true })
    @Column({ nullable: true, default: WikiStatus.Active })
    status: WikiStatus

    @Field(_type => WikiImportant, { nullable: true })
    @Column({ nullable: true, default: WikiImportant.Common })
    important: WikiImportant

    @Field(_type => Float, { nullable: true })
    @Column({ nullable: true, default: 0 })
    viewCount: number

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

    /*relation*/
    @ManyToOne(() => DocumentFolder, (ob) => ob.wikis)
    folder: DocumentFolder

    @OneToMany(() => VersionWiki, (ob) => ob.wiki)
    versions: VersionWiki[]

    @ManyToOne(() => OfficeUser)
    userCreator: OfficeUser

    @ManyToMany(() => CategoryWiki, (ob) => ob.wikis)
    categories: CategoryWiki[]

    @ManyToMany(() => TagDocument, (ob) => ob.wikis)
    @Field(_type => [TagDocument], { nullable: true })
    tags: TagDocument[]

    @ManyToMany(() => OfficeOrgChart)
    @JoinTable(BRIDGE_TABLE_DB_OBJ.WIKI_ORG_CHART)
    orgCharts: OfficeOrgChart[]

    /*Method*/
    public async isCanCreateNewVersion(): Promise<boolean> {
        return !(await VersionWiki.createQueryBuilder()
            .where({
                wiki: { id: this.id },
                status: In([VersionWikiStatus.Pending, VersionWikiStatus.UnderReview])
            })
            .getCount())
    }

    /*Listener*/
    @BeforeInsert()
    async genData() {
    }
}