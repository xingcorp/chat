import { Injectable } from "@nestjs/common";
import { DataSource, Repository } from "typeorm";
import { ApprovalForwardUser } from "@models/entities";

@Injectable()
export class ApprovalForwardUserRepo extends Repository<ApprovalForwardUser> {
    constructor(
        private dataSource: DataSource,
    ) {
        super(ApprovalForwardUser, dataSource.createEntityManager());
    }
}