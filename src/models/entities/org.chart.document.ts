import { Field, Float, ObjectType, registerEnumType } from "@nestjs/graphql"
import { AfterInsert, BaseEntity, BeforeInsert, Column, CreateDateColumn, DeleteDateColumn, Entity, Generated, PrimaryGeneratedColumn, UpdateDateColumn } from "typeorm"

export enum DocumentType {
    File = 'File',
    Folder = 'Folder',
    Wiki = 'Wiki',
}

export enum ObjectEffect {
    Allow = 'Allow',
    Deny = 'Deny'
}

registerEnumType(DocumentType, { name: 'DocumentType' })
registerEnumType(ObjectEffect, { name: 'ObjectEffect' })

@ObjectType()
@Entity("office-org-chart-documents")
export class OrgChartDocument extends BaseEntity {
    // @Field(_type => String)
    @PrimaryGeneratedColumn("uuid")
    id: string

    // @Field(() => String, { nullable: false })
    @Column({ nullable: true })
    departmentId: string

    @Column({ nullable: true })
    userId: string

    // @Field(() => String, { nullable: false })
    @Column({ nullable: false })
    documentId: string

    @Column({ nullable: false, type: 'enum', enum: DocumentType })
    type: DocumentType

    @Column({ nullable: false, type: 'enum', enum: ObjectEffect, default: ObjectEffect.Allow })
    effect: ObjectEffect

    // @Field(_type => Float)
    @CreateDateColumn()
    createdAt: Date

    // @Field({ nullable: true })
    @Column({ nullable: true })
    createdBy: string

    // @Field(_type => Float)
    @UpdateDateColumn()
    updatedAt: Date

    // @Field({ nullable: true })
    @Column({ nullable: true })
    updatedBy: string

    @DeleteDateColumn()
    deletedAt: Date
}