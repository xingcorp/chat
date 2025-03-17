import { Injectable } from "@nestjs/common";
import { DataSource, In, Repository } from "typeorm";
import { BookingMeetingRoom } from "@models/entities";
import { RequestContext } from "@common/context/request.context";

@Injectable()
export class BookingMeetingRoomRepo extends Repository<BookingMeetingRoom> {
    constructor(private dataSource: DataSource) {
        super(BookingMeetingRoom, dataSource.createEntityManager());
    }

    private getListOrgIds() {
        let orgIds = RequestContext.currentOrgData('listOrgIdOnly')
        if (RequestContext.isNormalUser()) {
            orgIds = RequestContext.currentOrgData('listOrgIdAll') //ok
        }

        return orgIds
    }

    async getById(id: string) {
        const listOrgIds = this.getListOrgIds()

        return this.findOne({
            where: {
                id,
                organizationId: In([...listOrgIds])
            },
        })
    }

    async list() {
        const listOrgIds = this.getListOrgIds()

        return this.find({
            where: {
                organizationId: In([...listOrgIds])
            },
        })
    }

    async getBy(where: any, relations?: string[]) {
        const query = this.createQueryBuilder('qb')

        if (relations) {
            relations.map(i => query.leftJoinAndSelect(`qb.${i}`, `${i}`))
        }

        return query
            .where(where)
            .getOne()
    }
}