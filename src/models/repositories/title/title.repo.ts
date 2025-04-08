import { Injectable } from "@nestjs/common";
import { DataSource, Repository } from "typeorm";
import { OfficeTitle } from "@models/entities";
import { FindOptionsWhere } from "typeorm/find-options/FindOptionsWhere";

@Injectable()
export class TitleRepo extends Repository<OfficeTitle> {
    constructor(private dataSource: DataSource) {
        super(OfficeTitle, dataSource.createEntityManager());
    }

    async getBy(where: any) {
        return this.createQueryBuilder()
            .where(where)
            .getOne()
    }

    async checkValidBy(where: FindOptionsWhere<OfficeTitle> | FindOptionsWhere<OfficeTitle>[]) {
        const ids = (await this.find()).map(i => i.id)

        return ids.includes((await this.findOneBy(where))?.id)
    }
}