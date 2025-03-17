import { Injectable } from "@nestjs/common";
import { DataSource, Repository } from "typeorm";
import { WhitelistIP } from "@models/entities";

@Injectable()
export class WhiteListIpRepo extends Repository<WhitelistIP> {
    constructor(private dataSource: DataSource) {
        super(WhitelistIP, dataSource.createEntityManager());
    }

    async isAllow(publicIp: string) {
        return !!(await this.findOneBy({publicIp}))
    }
}