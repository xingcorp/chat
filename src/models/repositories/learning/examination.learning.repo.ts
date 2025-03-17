import { Injectable } from "@nestjs/common";
import { DataSource, Repository } from "typeorm";
import { LearnExaminations } from "@models/entities";

@Injectable()
export class ExaminationLearningRepo extends Repository<LearnExaminations> {
    constructor(private dataSource: DataSource) {
        super(LearnExaminations, dataSource.createEntityManager());
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