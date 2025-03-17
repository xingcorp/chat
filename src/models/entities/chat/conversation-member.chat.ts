import { Field, Float, Int, ObjectType } from "@nestjs/graphql";
import {
    BaseEntity,
    Column,
    CreateDateColumn,
    DeleteDateColumn,
    Entity, Index, ManyToOne,
    PrimaryGeneratedColumn,
    UpdateDateColumn
} from "typeorm";
import { OfficeUser } from "@models/entities";
import { OfficeChatConversation } from "@models/entities/chat/conversation.chat";

@ObjectType()
@Entity("office-chat-conversation-member")
export class OfficeChatConversationMember extends BaseEntity {

    @Field(_type => String, { nullable: true })
    @PrimaryGeneratedColumn("uuid")
    id: string

    // @Field(_type => Boolean, { nullable: true })
    // @Column({ nullable: false, default: false })
    // roomMaster: Boolean

    // @Field(_type => Boolean, { nullable: true })
    // @Column({ nullable: false, default: false })
    // superAdmin: Boolean

    @Field(_type => Boolean, { nullable: true })
    @Column({ nullable: false, default: false })
    admin: Boolean

    @Field(_type => Boolean, { nullable: true })
    @Column({ nullable: false, default: false })
    connected: Boolean

    @Field(_type => Boolean, { nullable: true })
    @Column({ nullable: false, default: false })
    hide: Boolean

    @Field(_type => Float, { nullable: true })
    @CreateDateColumn()
    createdAt: Date

    @Field(_type => Float, { nullable: true })
    @Column({ nullable: true })
    viewMessagesFrom: Date

    @Field(_type => Float, { nullable: true })
    @UpdateDateColumn()
    updatedAt: Date

    @Field({ nullable: true })
    @Column({ nullable: true })
    updatedBy: string

    @DeleteDateColumn()
    deletedAt: Date

    @Field(_type => OfficeUser, { nullable: false })
    @ManyToOne(() => OfficeUser, (ob) => ob.conversations)
    user: OfficeUser

    @Field(_type => String, { nullable: true })
    @Column({ nullable: true })
    @Index()
    userId: string

    @Field(_type => OfficeUser, { nullable: false })
    @ManyToOne(() => OfficeUser, (ob) => ob.conversations)
    creator: OfficeUser

    @Column({ nullable: true })
    creatorId: string

    @Field(_type => String, { nullable: true })
    @Column({ nullable: true })
    lastMessageReadId: string

    @Field(_type => Int, { nullable: true, defaultValue: 0 })
    @Column({ nullable: true, default: 0 })
    unreadCount: number

    @Field(_type => OfficeChatConversation, { nullable: false })
    @ManyToOne(() => OfficeChatConversation, (ob) => ob.members)
    conversation: OfficeChatConversation

    @Field(_type => String, { nullable: true })
    @Column({ nullable: true })
    @Index()
    conversationId: string
}