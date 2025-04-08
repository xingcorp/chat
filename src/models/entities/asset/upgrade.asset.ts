import { Field, Float, ObjectType } from "@nestjs/graphql";
import {
    BaseEntity,
    Column,
    CreateDateColumn,
    DeleteDateColumn,
    Entity, ManyToOne,
    PrimaryGeneratedColumn,
    UpdateDateColumn
} from "typeorm";
// import { Asset, OfficeUser } from "@models/entities";

@ObjectType()
@Entity("office-asset-assignment")
export class AssignmentAsset extends BaseEntity {
    @Field(_type => String)
    @PrimaryGeneratedColumn("uuid")
    id: string

    @Field(_type => String, { nullable: true })
    @Column({ nullable: true })
    code: string

    @Field(_type => Float, {nullable: true})
    @Column({type: 'timestamptz', nullable: true})
    startTime: Date

    @Field(_type => Float, {nullable: true})
    @Column({type: 'timestamptz', nullable: true})
    endTime: Date

    @Field(_type => String, {nullable: true})
    @Column({nullable: true})
    reason: string

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

    /*Todo:*/
    /*@Field(_type => OfficeUser, {nullable: true})
    @ManyToOne(() => OfficeUser, (ob) => ob.assignmentAssets, {
        eager: true
    })
    assigned: OfficeUser*/

    /*@Field(_type => Asset, { nullable: true })
    @ManyToOne(() => Asset, (ob) => ob.assignments, {
        eager: true
    })
    asset: Asset*/

    /*@Field(_type => OfficeUser, {nullable: true})
    @ManyToOne(() => OfficeUser, (ob) => ob.handoverAssets, {
        eager: true
    })
    handover: OfficeUser*/
}