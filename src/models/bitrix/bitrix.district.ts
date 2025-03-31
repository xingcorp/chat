import { Field, Float, ObjectType } from "@nestjs/graphql"
import { BeforeInsert, Column, Entity } from "typeorm"
import { IndexBase } from "../office.base"
@Entity("crm-bitrix-districts")
@ObjectType()
export class BitrixDistrict extends IndexBase {
    @Field(_type => String, { nullable: true })
    @Column({ nullable: true })
    krfId: string

    @Field(_type => String, { nullable: true })
    @Column({ nullable: true })
    eco248Id: string

    @Field(_type => String, { nullable: true })
    @Column({ nullable: true })
    name: string
}