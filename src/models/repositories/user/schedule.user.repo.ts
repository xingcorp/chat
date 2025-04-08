import { Injectable } from "@nestjs/common";
import { DataSource, Repository } from "typeorm";
import { UserSchedule } from "@models/entities";

@Injectable()
export class UserScheduleRepo extends Repository<UserSchedule> {
    constructor(
        private dataSource: DataSource,
    ) {
        super(UserSchedule, dataSource.createEntityManager());
    }

    async getByUserId(id: string) {
        return this.findOneBy({ ownerId: id })
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

    async getManyBy(where: any, relations?: string[]) {
        const query = this.createQueryBuilder('qb')

        if (relations) {
            relations.map(i => query.leftJoinAndSelect(`qb.${i}`, `${i}`))
        }

        return query
            .where(where)
            .getMany()
    }
}