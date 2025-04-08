import { Field, Int, Float, ObjectType, registerEnumType } from "@nestjs/graphql";
import { __Type } from "graphql";
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
    Generated,
    OneToMany,
    PrimaryGeneratedColumn,
    Unique,
    UpdateDateColumn
} from "typeorm";
import { ObjectStatus } from "./profile.info.block";
import { OfficeTask } from "@models/entities/task/task";
import { DocumentWiki } from "@models/entities/wiki/wiki";

export enum DocumentScope {
    Public = 'Public',
    Private = 'Private'
}

registerEnumType(DocumentScope, { name: 'DocumentScope' })

@ObjectType()
@Entity("office-document-folders")
export class DocumentFolder extends BaseEntity {
    @Field(_type => String, { nullable: true })
    @PrimaryGeneratedColumn("uuid")
    id: string

    @Field(_type => String)
    @Column({ nullable: false })
    name: string

    @Field(_type => DocumentScope)
    @Column({ nullable: false, type: 'enum', enum: DocumentScope, default: DocumentScope.Public })
    scope: DocumentScope

    @Field(_type => String, { nullable: true })
    @Column({ nullable: true })
    note: string

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

    @Field(_type => DocumentWiki, { nullable: true })
    @OneToMany(() => DocumentWiki, (ob) => ob.folder)
    wikis: DocumentWiki[]

    @BeforeInsert()
    async beforeInsert() {
        if (!this.id) this.id = RandomHelper.generateUUID()
        if (this.parentId) {
            const parent = await DocumentFolder.findOne({
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