import { Injectable } from '@nestjs/common';
import {InjectConnection} from "@nestjs/typeorm";
import {Brackets, Connection, IsNull, Not} from "typeorm";
import {QueryMeetingRoomsArgs} from "./meeting.room.args";
import { MeetingRoom, OfficeOrgChart } from "../../../../models/entities";
import { OfficeOrgChartRepo } from "@models/repositories/office-org-chart.repo";
import { OfficeSysUserRepo } from "@models/repositories/office-sys-user.repo";
import { ObjectStatus } from '@models/entities/profile.info.block';
import { RequestContext } from "@common/context/request.context";

@Injectable()
export class MeetingRoomService {
    constructor(
        @InjectConnection()
        private readonly connection: Connection,

        private orgChartRepository: OfficeOrgChartRepo,
        private officeSysUserRepo: OfficeSysUserRepo,
    ) { }

    public async getAdminMeetingRooms(filter: QueryMeetingRoomsArgs, requesterId: string) {
        const options: any = {}

        return this.getMeetingRooms(filter, requesterId, options)
    }

    public async getAppMeetingRooms(filter: QueryMeetingRoomsArgs, requesterId: string) {
        const options: any = {
            status: ObjectStatus.Active,
            // approvalFormId: Not(IsNull())
        }

        return this.getMeetingRooms(filter, requesterId, options)
    }

    private async getMeetingRooms(filter: QueryMeetingRoomsArgs, requesterId: string, options: any) {
        filter.size = filter.size ? filter.size : 100 //7
        filter.page = filter.page ? (filter.page - 1) : 0

        let query = MeetingRoom.createQueryBuilder('room')
            // .leftJoinAndSelect(OfficeOrgChart, 'orgChart', 'room.organizationId="orgChart".id::varchar')
            // .leftJoinAndMapOne('room.orgChart',
            //     OfficeOrgChart,
            //     'orgChart',
            //     '"orgChart".id::varchar = room.organizationId',
            // )
            .where(options)
            .take(filter.size)
            .skip(filter.page * filter.size)
            .orderBy('room.createdAt', 'DESC')

        /*SOF-2034*/
        let oogIds: string[] = []

        if (RequestContext.isNormalUser()) {
            oogIds = RequestContext.currentOrgData('listOrgIdWParentAndChild')
        } else {
            oogIds = RequestContext.currentOrgData('listOrgIdWChild')
        }

        query.andWhere(`room."organizationId"::text IN (:...oogIds)`, {oogIds})

        if (filter.organizationId) {
            query = query.where({ organizationId: filter.organizationId })
        }
        if (filter.keyword) {
            query =
                query.andWhere(new Brackets(db => {
                    db.where(`unaccent(LOWER(room.name)) ILIKE unaccent(LOWER(:keyword))`, { keyword: `%${filter.keyword.trim()}%`})
                        .orWhere(`unaccent(LOWER(room.code)) ILIKE unaccent(LOWER(:keyword))`, { keyword: `%${filter.keyword.trim()}%`})
                }))
        }
        if (filter.status) {
            query = query.andWhere({ status: filter.status })
        }
        if (filter.approvalFormId) {
            query = query.andWhere({ approvalFormId: filter.approvalFormId })
        }

        return query.getManyAndCount()
    }
}
