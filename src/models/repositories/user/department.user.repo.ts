import { Injectable } from "@nestjs/common";
import { DataSource, Repository } from "typeorm";
import { UserDepartment } from "@models/entities";

@Injectable()
export class UserDepartmentRepo extends Repository<UserDepartment> {
    constructor(private dataSource: DataSource) {
        super(UserDepartment, dataSource.createEntityManager());
    }

    async getByUserId(id: string) {
        return this.findOneBy({userId: id})
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