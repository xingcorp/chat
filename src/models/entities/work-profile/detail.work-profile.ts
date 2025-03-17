import { Field, Float, ObjectType } from "@nestjs/graphql";
import {
    BaseEntity, BeforeInsert,
    Column, CreateDateColumn, DeleteDateColumn,
    Entity, JoinColumn,
    JoinTable,
    ManyToMany,
    ManyToOne,
    OneToMany, OneToOne,
    PrimaryGeneratedColumn, UpdateDateColumn
} from "typeorm";
import { OfficeOrgChart, OfficeTitle, OfficeUser, UserWorkProfile } from "@models/entities";

@ObjectType()
@Entity("office-user-work-profile-detail")
export class UserWorkProfileDetail extends BaseEntity {
    @Field(_type => String)
    @PrimaryGeneratedColumn("uuid")
    id: string

    @Field(_type => String, {nullable: true})
    @Column({nullable: true})
    userCode: string

    @Field(_type => OfficeOrgChart, {nullable: true})
    @ManyToOne(() => OfficeOrgChart, (ob) => ob.workProfiles, {
        eager: true
    })
    department: OfficeOrgChart

    @Field(_type => OfficeTitle, {nullable: true})
    @ManyToOne(() => OfficeTitle, (ob) => ob.workProfiles, {
        eager: true
    })
    title: OfficeTitle

    @Field(_type => String, {nullable: true})
    @Column({nullable: true})
    major: string

    @Field(_type => OfficeUser, {nullable: true})
    @ManyToOne(() => OfficeUser, (ob) => ob.mentees, {
        eager: true
    })
    leader: OfficeUser

    // @Column('jsonb', {nullable: true, default: {}})
    @Column({
        type: "jsonb",
        nullable: true,
        transformer: {
            to(value: any): string {
                return JSON.stringify(value)
            },
            from(value: string): any {
                return JSON.parse(value);
            },
        },
    })
    metadata: any

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