import { Field, Float, Int, ObjectType } from "@nestjs/graphql"
import { RandomHelper } from "src/common/random"
import { BaseEntity, BeforeInsert, Column, CreateDateColumn, DeleteDateColumn, Entity, PrimaryGeneratedColumn, UpdateDateColumn } from "typeorm"
import { DocumentFolder } from "./document.folder"

@Entity('office-document-files')
@ObjectType()
export class DocumentFile extends BaseEntity {
    @Field(_type => String, { nullable: true })
    @PrimaryGeneratedColumn("uuid")
    id: string

    @Field(_type => String)
    @Column({ nullable: false })
    name: string

    @Field({ nullable: true })
    @Column()
    mimetype: string

    @Field({ nullable: true })
    @Column()
    encoding: string

    @Field(() => Float, { nullable: true })
    @Column({ type: 'bigint', nullable: true })
    size: string

    @Field(_type => String, { nullable: false })
    @Column({ nullable: false, default: 'root' })
    folderId: string

    @Field(_type => String, { nullable: false })
    @Column({ nullable: false })
    path: string

    @Field({ nullable: true })
    @Column({ nullable: true })
    location: string

    //AWS S3
    @Column({ nullable: true })
    etag: string

    @Column({ nullable: true })
    key: string

    @Column({ nullable: true })
    bucket: string

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

    @BeforeInsert()
    async beforeInsert() {
        if (!this.id) this.id = RandomHelper.generateUUID()
        if (this.folderId) {
            const folder = await DocumentFolder.findOne({
                where: {
                    id: this.folderId
                }
            })
            this.path = `${folder.path}/${this.id}`
        } else {
            this.path = `/${this.id}`
        }
    }
}