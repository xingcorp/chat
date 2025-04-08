import { Injectable } from "@nestjs/common";
import { DataSource, Repository } from "typeorm";
import { OfficeSysUser } from "@models/entities/system.user";

@Injectable()
export class OfficeSysUserRepo extends Repository<OfficeSysUser>{
    constructor(private dataSource: DataSource) {
        super(OfficeSysUser, dataSource.createEntityManager());
    }

    async getOrgChartIds(id: string) {
        const user = await this.findOne({
            where: {
                id,
            }
        })

        return user?.orgChartIds
    }
}