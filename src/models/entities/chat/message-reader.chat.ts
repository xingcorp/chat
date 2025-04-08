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
import { OfficeChatMessage, OfficeUser } from "@models/entities";

@ObjectType()
@Entity("office-chat-message-reader")
export class OfficeChatMessageReader extends BaseEntity {
    @Field(_type => String)
    @PrimaryGeneratedColumn("uuid")
    id: string

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

    @Field(_type => OfficeUser, { nullable: false })
    @ManyToOne(() => OfficeUser, (ob) => ob.messagesReader)
    user: OfficeUser

    // @Field(_type => OfficeChatMessage, { nullable: false })
    // @ManyToOne(() => OfficeChatMessage, (ob) => ob.readBy)
    // message: OfficeChatMessage
}