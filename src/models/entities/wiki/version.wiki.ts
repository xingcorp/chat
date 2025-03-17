import { Field, Float, ObjectType, registerEnumType } from "@nestjs/graphql";
import {
    AfterLoad,
    BaseEntity, BeforeInsert,
    Column, CreateDateColumn, DeleteDateColumn,
    Entity, ManyToMany, ManyToOne,
    PrimaryGeneratedColumn, UpdateDateColumn,
} from "typeorm";
import { OfficeUser, TagDocument } from "@models/entities";
import { DocumentWiki } from "@models/entities/wiki/wiki";
import { UpdateTypeEnum, VersionWikiStatus } from "@enum/wiki/wiki.enum";

registerEnumType(UpdateTypeEnum, {name: 'UpdateTypeEnum'})
registerEnumType(VersionWikiStatus, {name: 'VersionWikiStatus'})

@ObjectType()
@Entity("office-document-wiki-versions")
export class VersionWiki extends BaseEntity {
    @Field(_type => String)
    @PrimaryGeneratedColumn("uuid")
    id: string

    @Field(_type => Float, {nullable: true})
    @Column({nullable: true})
    no: number

    @Field({nullable: true})
    @Column({nullable: true})
    code: string

    @Field({nullable: true})
    @Column({nullable: true})
    version: string

    @Field({nullable: true})
    versionTitle: string

    @Field({nullable: true})
    fullName: string

    @Field(_type => UpdateTypeEnum, { nullable: true })
    @Column({nullable: true})
    updateType: UpdateTypeEnum

    @Field({nullable: true})
    @Column({nullable: true})
    name: string

    @Field({nullable: true})
    @Column({nullable: true})
    content: string

    @Column('text', { nullable: true, array: true })
    thumbnailIds: string[]

    @Column('text', { nullable: true, array: true })
    attachmentIds: string[]

    @Field({nullable: true})
    @Column({nullable: true, default: false})
    isPublic: boolean

    @Field({nullable: true})
    @Column({nullable: true, default: false})
    isLatestVersion: boolean

    @Field(_type => VersionWikiStatus)
    @Column({ nullable: true, default: VersionWikiStatus.UnderReview })
    status: VersionWikiStatus

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

    @ManyToOne(() => DocumentWiki, (ob) => ob.versions)
    wiki: DocumentWiki

    @ManyToOne(() => OfficeUser, {eager: true})
    userCreator: OfficeUser

    @ManyToOne(() => VersionWiki, {eager: true})
    versionRevert: VersionWiki

    @ManyToOne(() => VersionWiki, {eager: true})
    lastVersion: VersionWiki

    @ManyToMany(() => TagDocument, (ob) => ob.wikiVersions)
    @Field(_type => [TagDocument], { nullable: true })
    tags: TagDocument[]

    /**/
    @AfterLoad()
    getVirtualField() {
        if (this.version) this.versionTitle = `v${this.version}`

        this.fullName = this.versionTitle ? `${this.name} ${this.versionTitle}` : this.name
    }

    /**/
    @BeforeInsert()
    async genData() {
    }
}