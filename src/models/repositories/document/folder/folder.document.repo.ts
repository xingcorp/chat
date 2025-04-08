import { Injectable } from "@nestjs/common";
import { DataSource, Repository } from "typeorm";
import { DocumentFolder } from "@models/entities";

@Injectable()
export class FolderDocumentRepo extends Repository<DocumentFolder> {
    constructor(private dataSource: DataSource) {
        super(DocumentFolder, dataSource.createEntityManager());
    }

    async getBy(where: any) {
        return this.createQueryBuilder()
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