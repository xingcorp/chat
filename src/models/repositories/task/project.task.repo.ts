import { Injectable } from "@nestjs/common";
import { DataSource, Repository } from "typeorm";
import { OfficeTaskProject } from "@models/entities";

const KEY_DEFAULT = "TASK"

@Injectable()
export class OfficeTaskProjectRepo extends Repository<OfficeTaskProject> {
    constructor(private dataSource: DataSource) {
        super(OfficeTaskProject, dataSource.createEntityManager());
    }

    async getFirstByOrgId(orgId: string) {
        return this.findOneBy({
            rootOrg: {
                id: orgId
            }
        })
    }

    createDefault() {
        return this.create({
            key: KEY_DEFAULT
        })
    }
}