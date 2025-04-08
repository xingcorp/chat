import { Injectable } from "@nestjs/common";
import { Brackets, DataSource, Repository } from "typeorm";
import { LearnRequirement } from "@models/entities";

@Injectable()
export class RequirementLearningRepo extends Repository<LearnRequirement> {
    constructor(private dataSource: DataSource) {
        super(LearnRequirement, dataSource.createEntityManager());
    }

    getBy(where: any, relations?: string[]) {
        const query = this.createQueryBuilder('qb')

        return query
            .where(where)
            .getOne()
    }

    getManyBy(where: any, relations?: string[]) {
        const query = this.createQueryBuilder('qb')

        return query
            .where(where)
            .getMany()
    }
}