import { ObjectType, Field, Float } from '@nestjs/graphql'
import { Column, Entity } from 'typeorm'
import { IndexBase } from '../office.base'


@Entity('crm-bitrix-deals')
@ObjectType()
export class BitrixDeal extends IndexBase {
    @Field(_type => String, { nullable: true })
    @Column({ nullable: true })
    UF_KH_TEN: string  // tên khách

    @Field(_type => String, { nullable: true })
    @Column({ nullable: true })
    UF_KH_SDT: string  // số điện thoại

    @Field(_type => String, { nullable: true })
    @Column({ nullable: true })
    UF_KH_DIACHI: string  // địa chỉ chi tiết

    @Field(_type => String, { nullable: true })
    @Column({ nullable: true })
    UF_CRM_5D12D5E419C8D: string  // tỉnh

    @Field(_type => String, { nullable: true })
    @Column({ nullable: true })
    UF_CRM_5D12D5E43E827: string  // thành phố/quận huyện

    @Field(_type => String, { nullable: true })
    @Column({ nullable: true })
    UF_CRM_5D12D5E45FE1D: string  // phường xã

    @Field(_type => String, { nullable: true })
    @Column({ nullable: true })
    DATE_CREATE: string  // ngày tạo

    @Field(_type => Float, { nullable: true })
    @Column({ nullable: true })
    bitrixCreatedAt: Date

    @Field(_type => Float, { nullable: true })
    @Column({ nullable: true })
    syncToBitrixEco248: number
}