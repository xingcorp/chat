import { Injectable } from '@nestjs/common';
import { CheckInPlaceFilter } from "./checkin.args";
import { Brackets } from "typeorm";
import { CheckInPlace } from "../../../models/entities";
import { UserType } from "@core/middleware/guard/service.action";
import { OfficeError } from "@common/office.error";

@Injectable()
export class CheckinService {

    constructor() {}

    public async checkInGetPlaceList(filter: CheckInPlaceFilter, userType: string) {

        if (userType === UserType.NORMAL_USER && (!filter.latitude || !filter.longitude)) {
            throw OfficeError.CheckInRequiredLocationPermission
        }

        filter.size = filter.size ? filter.size : 20 //1
        filter.page = filter.page ? (filter.page - 1) : 0

        let query = CheckInPlace.createQueryBuilder('qb')
            .where({})
            .take(filter.size)
            .skip(filter.page * filter.size)
            .orderBy('qb.createdAt', 'DESC')

        if (filter && filter.hasOwnProperty('ipValidation')) {
            query = query.andWhere({ ipValidation: filter.ipValidation })
        }

        if (filter && filter.provinceId) {
            query = query.andWhere({ provinceId: filter.provinceId })
        }

        if (filter && filter.districtId) {
            query = query.andWhere({ districtId: filter.districtId })
        }

        if (filter && filter.wardId) {
            query = query.andWhere({ wardId: filter.wardId })
        }

        if (filter && filter.keyword) {
            query =
                query.andWhere(new Brackets(db => {
                    db.where(`unaccent(LOWER(qb.name)) ILIKE unaccent(LOWER(:keyword))`, { keyword: `%${filter.keyword.trim()}%`})
                        .orWhere(`unaccent(LOWER(qb.code)) ILIKE unaccent(LOWER(:keyword))`, { keyword: `%${filter.keyword.trim()}%`})
                        .orWhere(`unaccent(LOWER(qb.note)) ILIKE unaccent(LOWER(:keyword))`, { keyword: `%${filter.keyword.trim()}%`})
                }))
        }

        /* check function get distance in common.utils calculateDistanceInKm*/
        if (filter && filter.longitude && filter.latitude) {
            query
                .andWhere(`
                2 * ATAN2(
                    SQRT(POWER(SIN(ABS(qb.latitude - :lat) * (PI() / 180) / 2), 2) + POWER(SIN(ABS(qb.longitude - :long) * (PI() / 180) / 2), 2) * COS(:lat * (PI() / 180)) * COS(qb.latitude * (PI() / 180))),
                    SQRT(1 - (POWER(SIN(ABS(qb.latitude - :lat) * (PI() / 180) / 2), 2) + POWER(SIN(ABS(qb.longitude - :long) * (PI() / 180) / 2), 2) * COS(:lat * (PI() / 180)) * COS(qb.latitude * (PI() / 180))))
                ) * 6371 * 1000 <= :limit
            `, {
                lat: filter.latitude,
                long: filter.longitude,
                limit: filter.limit,
            })
        }

        console.log(query.getQueryAndParameters())

        const [list, count] = await query.getManyAndCount()

        return {
            total: count,
            count: list.length,
            places: list
        }
    }
}
