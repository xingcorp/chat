import { Field, Float, ObjectType } from "@nestjs/graphql"
import { BeforeInsert, Column, Entity } from "typeorm"
import { IndexBase } from "../office.base"
@Entity("crm-eco248-leads")
@ObjectType()
export class Eco248Lead extends IndexBase {
    @Field(_type => String, { nullable: true })
    @Column({ nullable: true })
    PHONE: string

    @Field(_type => String, { nullable: true })
    @Column({ nullable: true })
    STATUS_ID: string

    @Field(_type => String, { nullable: true })
    @Column({ nullable: true })
    TITLE: string

    @Field(_type => String, { nullable: true, defaultValue: "13" }) // Karofi CSKH
    @Column({ nullable: true, default: "13" })
    SOURCE_ID: string

    @Field(_type => String, { nullable: true, defaultValue: "103" }) // tỉnh thành: Hà Nội
    @Column({ nullable: true, default: "103" })
    UF_CRM_1606325864: string

    @Field(_type => String, { nullable: true }) // quận/huyện
    @Column({ nullable: true })
    UF_CRM_1610013827: string

    @Field(_type => String, { nullable: true }) // địa chỉ
    @Column({ nullable: true })
    UF_CRM_1607052064996: string

    @Field(_type => String, { nullable: true, defaultValue: "BHBT_KRF" }) // note
    @Column({ nullable: true, default: "BHBT_KRF" })
    UF_CRM_1607066687948: string

    @Field(_type => String, { nullable: true, defaultValue: "651" }) // loại LEAD: BTBD
    @Column({ nullable: true, default: "651" })
    UF_CRM_1608865188845: string

    @Field(_type => String, { nullable: true, defaultValue: "1527" }) // người chịu trách nhiệm: test
    @Column({ nullable: true, default: "1527" })
    ASSIGNED_BY_ID: string

    @Field(_type => Float, { nullable: true })
    @Column({ nullable: true })
    bitrixCreatedAt: Date

    @Field(_type => Float, { nullable: true })
    @Column({ nullable: true })
    syncToBitrixEco248: number

    @Field(_type => String, { nullable: true })
    @Column({ nullable: true })
    eco248Response: string

    @Field(_type => String, { nullable: true })
    @Column({ nullable: true })
    eco248Id: string

    @Field(_type => String, { nullable: true })
    @Column({ nullable: true })
    bitrixLeadId: string
}