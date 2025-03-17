import { Field, Float, ObjectType, registerEnumType } from "@nestjs/graphql";
import {
    BaseEntity,
    Column,
    CreateDateColumn,
    DeleteDateColumn,
    Entity, JoinColumn, JoinTable, ManyToMany,
    ManyToOne, OneToMany, OneToOne,
    PrimaryGeneratedColumn,
    UpdateDateColumn
} from "typeorm";
import { ActiveStatus } from "@common/enum.common";
import { ApprovalForwardUser, OfficeApproval } from "@models/entities";

registerEnumType(ActiveStatus, {name: 'ActiveStatus'})

@ObjectType()
@Entity("office-approval-forward")
export class ApprovalForward extends BaseEntity {
    @Field(_type => String)
    @PrimaryGeneratedColumn("uuid")
    id: string

    @Field(_type => String)
    @Column({ nullable: true })
    note: string

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

    /*relation*/
    @OneToMany(() => ApprovalForwardUser, (ob) => ob.forward)
    users: ApprovalForwardUser[]

    @OneToOne(() => OfficeApproval, (ob) => ob.forward, {
        nullable: true,
        eager: true
    })
    @JoinColumn()
    approval: OfficeApproval

    @ManyToOne(() => OfficeApproval, {
        nullable: true,
        eager: true
    })
    originApproval: OfficeApproval
}