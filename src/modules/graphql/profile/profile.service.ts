import { Injectable } from "@nestjs/common";
import { InjectConnection } from "@nestjs/typeorm";
import {Brackets, Connection} from "typeorm";
import { OfficeTitleFilter } from "./profile.args";
import { OfficeTitle } from "../../../models/entities";
import { InfoField } from "../../../models/entities";
import { OfficeError } from "../../../common/office.error";

@Injectable()
export class ProfileService {
    constructor(
        @InjectConnection()
        private readonly connection: Connection
    ) { }

    public async getAllInfoFields(): Promise<any> {
        let query = `select
                        oif.*,
                        oib.id as "blockId",
                        oib."name" as "blockName",
                        oib."no" as "blockNo",
                        oib.code as "blockCode",
                        oib.status as "blockStatus",
                        oib."order" as "blockOrder",
                        oib.note as "blockNote"
                    from office."office-info-fields" oif 
                    left join office."office-info-blocks" oib 
                    on oif."blockId" = oib.id::text
                    where oif."deletedAt" is null and oib."deletedAt" is null
                    order by "blockOrder", "order"`

        // console.log("QUERY: ", query)

        return this.connection.query(query)
    }

    // public async getFieldsByBlock(blockId: string): Promise<any> {
    //     let query = `select
    //                     oif.*,
    //                     oib.id as "blockId",
    //                     oib."name" as "blockName",
    //                     oib."no" as "blockNo",
    //                     oib.code as "blockCode",
    //                     oib.status as "blockStatus",
    //                     oib."order" as "blockOrder",
    //                     oib.note as "blockNote"
    //                 from office."office-info-fields" oif 
    //                 left join office."office-info-blocks" oib 
    //                 on oif."blockId" = oib.id::text
    //                 where oif."deletedAt" is null and oib."deletedAt" is null
    //                 order by "blockOrder", "order"`

    //     // console.log("QUERY: ", query)

    //     return this.connection.query(query)
    // }

    public async getTitleList(filter: OfficeTitleFilter) {
        filter.size = filter.size ? filter.size : 20 //3
        filter.page = filter.page ? (filter.page - 1) : 0

        let query = OfficeTitle.createQueryBuilder('ot')
            .where({})
            .take(filter.size)
            .skip(filter.page * filter.size)
            .orderBy('ot.createdAt', 'DESC')

        if (filter && filter.keyword) {
            query = query.andWhere(new Brackets(db => {
                db.where(`unaccent(LOWER(ot.name)) ILIKE unaccent(LOWER(:keyword))`, { keyword: `%${filter.keyword.trim()}%` })
                    .orWhere(`unaccent(LOWER(ot.code)) ILIKE unaccent(LOWER(:keyword))`, { keyword: `%${filter.keyword.trim()}%` })
                    .orWhere(`unaccent(LOWER(ot.note)) ILIKE unaccent(LOWER(:keyword))`, { keyword: `%${filter.keyword.trim()}%` })
            }))
        }
    
        return query.getManyAndCount();
    }

    public async profileRemoveBlockField(id: string, requesterId: string) {
        const existedField = await InfoField.findOne({
            where: { id: id }
        })

        if (!existedField) throw OfficeError.InfoFieldNotExisted

        existedField.updatedBy = requesterId
        await existedField.save()
        await existedField.softRemove()

        return id
    }
}