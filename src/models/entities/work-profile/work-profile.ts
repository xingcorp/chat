import { Field, Float, ObjectType } from "@nestjs/graphql";
import {
    BaseEntity, BeforeInsert,
    Column, CreateDateColumn, DeleteDateColumn,
    Entity,
    ManyToOne,
    OneToOne,
    PrimaryGeneratedColumn, UpdateDateColumn
} from "typeorm";
import { OfficeUser } from "@models/entities";
import { UserWorkProfileDetail } from "@models/entities/work-profile/detail.work-profile";
import { UserWorkProfileInfo } from "@models/entities/work-profile/info.work-profile";
import { stringNumberWithZeroLeading } from "@utils/string.utils";

@ObjectType()
@Entity("office-user-work-profile")
export class UserWorkProfile extends BaseEntity {
    @Field(_type => String, {nullable: true})
    @PrimaryGeneratedColumn("uuid")
    id: string

    @Field(_type => String, {nullable: true})
    @Column({nullable: true})
    code: string

    @Field(_type => OfficeUser, {nullable: true})
    @ManyToOne(() => OfficeUser, (ob) => ob.workProfiles, {
        eager: true
    })
    user: OfficeUser

    @Field(_type => UserWorkProfileInfo, {nullable: true})
    @OneToOne(() => UserWorkProfileInfo, (detail) => detail.workProfile, {
        eager: true
    })
    info: UserWorkProfileInfo

    @Field(_type => UserWorkProfileDetail, {nullable: true})
    @OneToOne(() => UserWorkProfileDetail, (detail) => detail.workProfile, {
        eager: true
    })
    detail: UserWorkProfileDetail

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

    @BeforeInsert()
    async genCode() {
        const count = await UserWorkProfile.count()

        this.code = `UWP${stringNumberWithZeroLeading(count + 1)}`
    }
}