import { Field, Float, ObjectType, registerEnumType } from "@nestjs/graphql";
import {
    BaseEntity,
    Column,
    CreateDateColumn, DeleteDateColumn,
    Entity,
    JoinColumn,
    ManyToOne,
    OneToOne,
    PrimaryGeneratedColumn, UpdateDateColumn
} from "typeorm";
import { UserWorkProfile } from "@models/entities";
import { WorkProfileAction, WorkProfileChangeType } from "@enum/work-profile/work-profile.enum";

registerEnumType(WorkProfileAction, {name: 'WorkProfileAction'})
registerEnumType(WorkProfileChangeType, {name: 'WorkProfileChangeType'})

@ObjectType()
@Entity("office-user-work-profile-info")
export class UserWorkProfileInfo extends BaseEntity {
    @Field(_type => String)
    @PrimaryGeneratedColumn("uuid")
    id: string

    @Field(_type => WorkProfileAction, { nullable: true })
    @Column({ nullable: true })
    actionType: WorkProfileAction

    @Field(_type => WorkProfileChangeType, { nullable: true })
    @Column({ nullable: true })
    type: WorkProfileChangeType

    @Field(_type => String, { nullable: true })
    @Column({ nullable: true })
    reason: String

    @Field(_type => Float, {nullable: true})
    @Column({type: 'timestamptz', nullable: true})
    activeDate: Date

    @Field(_type => Float, {nullable: true})
    @Column({type: 'timestamptz', nullable: true})
    endDate: Date

    @Field(_type => Boolean,{ nullable: true, defaultValue: false })
    @Column('boolean',{ nullable: true, default: false })
    isDecided: Boolean

    @Field(_type => String, { nullable: true })
    @Column({ nullable: true })
    decidedNumber: String

    @Field(_type => Float, {nullable: true})
    @Column({type: 'timestamptz', nullable: true})
    decidedDate: Date

    @Field(_type => String, { nullable: true })
    @Column({ nullable: true })
    note: String

    @Column('text', { nullable: true, array: true })
    attachmentIds: string[]

    @Field(_type => UserWorkProfile, {nullable: true})
    @OneToOne(() => UserWorkProfile)
    @JoinColumn()
    workProfile: UserWorkProfile

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