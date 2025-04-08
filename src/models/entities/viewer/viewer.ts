import { Field, Float, ObjectType } from "@nestjs/graphql";
import {
    BaseEntity,
    Column,
    CreateDateColumn,
    DeleteDateColumn,
    Entity,
    ManyToOne,
    PrimaryGeneratedColumn,
    UpdateDateColumn
} from "typeorm";
import { ViewerTypeEnum, ViewTypeEnum } from "@enum/viewer/viewer.enum";

@ObjectType()
@Entity("office-viewer")
export class Viewer extends BaseEntity {
    @Field(_type => String)
    @PrimaryGeneratedColumn("uuid")
    id: string

    @Column({nullable: true})
    relationType: ViewTypeEnum

    @Column({nullable: true})
    relationId: string

    @Column({nullable: true})
    viewerType: ViewerTypeEnum

    @Column( {nullable: true})
    viewerId: string

    @Column('float',{nullable: true, default: 1})
    count: number

    @Field(_type => Float)
    @CreateDateColumn()
    createdAt: Date

    @Field({nullable: true})
    @Column({nullable: true})
    createdBy: string

    @Field(_type => Float)
    @UpdateDateColumn()
    updatedAt: Date

    @Field({nullable: true})
    @Column({nullable: true})
    updatedBy: string

    @DeleteDateColumn()
    deletedAt: Date
}