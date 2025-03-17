import { Field, Float, ObjectType, registerEnumType } from "@nestjs/graphql";
import {
    BaseEntity,
    Column,
    CreateDateColumn,
    DeleteDateColumn,
    Entity, ManyToOne, OneToMany,
    PrimaryGeneratedColumn,
    UpdateDateColumn
} from "typeorm";
import { OfficeChatConversationMember } from "@models/entities/chat/conversation-member.chat";
import { OfficeUser } from "../profile.user";

export enum ChatConversationType {
    Direct = 'Direct',
    Group = 'Group',
}

export enum ChatConversationGroupType {
    Public = 'Public',
    Private = 'Private',
}

registerEnumType(ChatConversationType, { name: 'ChatConversationType' })
registerEnumType(ChatConversationGroupType, { name: 'ChatConversationGroupType' })

@ObjectType()
@Entity("office-chat-conversation")
export class OfficeChatConversation extends BaseEntity {
    @Field(_type => String)
    @PrimaryGeneratedColumn("uuid")
    id: string

    @Field(_type => String, { nullable: true })
    @Column({ nullable: true })
    name: string

    @Field(_type => ChatConversationType)
    @Column({ nullable: false, type: 'enum', enum: ChatConversationType, default: ChatConversationType.Direct })
    type: ChatConversationType

    @Field(_type => String, { nullable: true })
    @Column({ nullable: true })
    description: string

    @Field(_type => String, { nullable: true })
    @Column({ nullable: true })
    imgUrl: string

    @Field(_type => ChatConversationGroupType, { nullable: true })
    @Column({ nullable: true })
    groupType: ChatConversationGroupType

    @Field(_type => Float, { nullable: true })
    @CreateDateColumn()
    createdAt: Date

    @Field(_type => Float, { nullable: true })
    @Column({ nullable: true, default: new Date() })
    lastMessageAt: Date

    @Field(_type => String, { nullable: true })
    @Column({ nullable: true })
    lastMessageId: string

    @Field(_type => OfficeUser, { nullable: false })
    @ManyToOne(() => OfficeUser, (ob) => ob.conversations)
    creator: OfficeUser

    @Column({ nullable: true })
    creatorId: string

    @Field(_type => Float)
    @UpdateDateColumn()
    updatedAt: Date

    @Field({ nullable: true })
    @Column({ nullable: true })
    updatedBy: string

    @DeleteDateColumn()
    deletedAt: Date

    @Field(_type => [OfficeChatConversationMember], { nullable: true })
    @OneToMany(() => OfficeChatConversationMember, (ob) => ob.conversation)
    members: OfficeChatConversationMember[]

    @Field(_type => OfficeChatConversationMember, { nullable: true })
    personalConversation: OfficeChatConversationMember
}