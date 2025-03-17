import { Field, Float, Int, ObjectType } from "@nestjs/graphql"
import { AfterInsert, AfterUpdate, BaseEntity, Column, CreateDateColumn, DeleteDateColumn, Entity, JoinColumn, ManyToOne, OneToMany, PrimaryGeneratedColumn, UpdateDateColumn } from "typeorm"
import { ObjectStatus } from "./profile.info.block"
import { OwnerBase } from "../office.base"


@ObjectType()
@Entity("office-default-avatars")
export class DefaultAvatar extends OwnerBase {
    @Field(_type => String, { nullable: false })
    @Column({ nullable: false })
    imageUrl: string

    @Field(_type => String, { nullable: false })
    @Column({ nullable: false })
    gender: string
}