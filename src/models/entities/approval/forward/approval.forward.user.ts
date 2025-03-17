import { Field, Float, ObjectType, registerEnumType } from "@nestjs/graphql";
import {
    BaseEntity,
    Column,
    CreateDateColumn,
    DeleteDateColumn,
    Entity, JoinColumn, JoinTable, ManyToMany,
    ManyToOne, OneToOne,
    PrimaryGeneratedColumn,
    UpdateDateColumn
} from "typeorm";
import { ActiveStatus } from "@common/enum.common";
import { BRIDGE_TABLE_DB_OBJ } from "@common/db/bridge-table.db";
import { OfficeApproval } from "@models/entities/approval";
import { OfficeUser } from "@models/entities/profile.user";
import { ApprovalForwardItem } from "@enum/approval/approval/approval.enum";
import { ApprovalForward } from "@models/entities";

registerEnumType(ActiveStatus, {name: 'ActiveStatus'})

@ObjectType()
@Entity("office-approval-forward-to-user")
export class ApprovalForwardUser extends BaseEntity {
    @Field(_type => String)
    @PrimaryGeneratedColumn("uuid")
    id: string

    @Field(_type => String)
    @Column({ nullable: true })
    note: string

    @Field(_type => [ApprovalForwardItem])
    @Column('simple-array', { nullable: true })
    showItems: ApprovalForwardItem[]

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
    @ManyToOne(() => ApprovalForward)
    forward: ApprovalForward

    @ManyToOne(() => OfficeUser)
    user: OfficeUser
}