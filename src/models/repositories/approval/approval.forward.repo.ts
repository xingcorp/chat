import { Injectable } from "@nestjs/common";
import { DataSource, Repository } from "typeorm";
import { ApprovalForward } from "@models/entities";

@Injectable()
export class ApprovalForwardRepo extends Repository<ApprovalForward> {
    constructor(
        private dataSource: DataSource,
    ) {
        super(ApprovalForward, dataSource.createEntityManager());
    }
}