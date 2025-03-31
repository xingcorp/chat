import { Field, ObjectType, Float } from '@nestjs/graphql'
import { Entity, Column, BeforeInsert } from 'typeorm'
import { IndexBase } from '../office.base'


@Entity('crm-bitrix-troubles')
@ObjectType()
export class BitrixTrouble extends IndexBase {
    @Field(_type => String, { nullable: true })
    @Column({ nullable: true })
    ID: string

    @Field(_type => String, { nullable: true })
    @Column({ nullable: true })
    IBLOCK_ID: string

    @Field(_type => String, { nullable: true })
    @Column({ nullable: true })
    NAME: string

    @Field(_type => String, { nullable: true })
    @Column({ nullable: true })
    IBLOCK_SECTION_ID: string

    @Field(_type => String, { nullable: true })
    @Column({ nullable: true })
    CREATED_BY: string

    @Field(_type => String, { nullable: true })
    @Column({ nullable: true })
    BP_PUBLISHED: string

    @Field(_type => String, { nullable: true })
    @Column({ nullable: true })
    CODE: string

    @Field(_type => String, { nullable: true }) // Ngày tạo
    @Column({ nullable: true })
    DATE_CREATE: string

    @Field(_type => String, { nullable: true }) // Tên khách hàng
    @Column({ nullable: true })
    PROPERTY_356: string

    @Field(_type => String, { nullable: true }) // SĐT
    @Column({ nullable: true })
    PROPERTY_359: string

    @Field(_type => String, { nullable: true }) // Địa chỉ chi tiết
    @Column({ nullable: true })
    PROPERTY_497: string

    @Field(_type => String, { nullable: true }) // Tỉnh
    @Column({ nullable: true })
    PROPERTY_360: string

    @Field(_type => String, { nullable: true }) // Thành phố/quận huyện
    @Column({ nullable: true })
    PROPERTY_361: string

    @Field(_type => String, { nullable: true }) // Phường xã
    @Column({ nullable: true })
    PROPERTY_362: string

    @Field(_type => String, { nullable: true }) // Nhóm yêu cầu
    @Column({ nullable: true })
    PROPERTY_369: string

    @Field(_type => String, { nullable: true }) // Loại yêu cầu
    @Column({ nullable: true })
    PROPERTY_370: string

    @Field(_type => String, { nullable: true }) // kĩ thuật viên
    @Column({ nullable: true })
    PROPERTY_383: string

    @Field(_type => Float, { nullable: true })
    @Column({ nullable: true })
    bitrixCreatedAt: Date

    @Field(_type => Float, { nullable: true })
    @Column({ nullable: true })
    syncToBitrixEco248: number

    @Field(_type => String, { nullable: true })
    @Column({ nullable: true })
    eco248LeadId: string

    @BeforeInsert()
    async parseBitrixCreatedAt() {
        if (this.DATE_CREATE) {
            this.bitrixCreatedAt = this.strToDate(this.DATE_CREATE)
        }
    }

    strToDate(dtStr) {
        if (!dtStr) return null
        let dateParts = dtStr.split("/");
        let timeParts = dateParts[2].split(" ")[1].split(":");
        dateParts[2] = dateParts[2].split(" ")[0];
        // month is 0-based, that's why we need dataParts[1] - 1
        return new Date(+dateParts[2], dateParts[1] - 1, +dateParts[0], timeParts[0], timeParts[1], timeParts[2]);
    }
}