import { Injectable } from "@nestjs/common";
import {
    DataSource,
    Repository,
} from "typeorm";
import { AssignmentAsset } from "@models/entities";

@Injectable()
export class AssignmentAssetRepo extends Repository<AssignmentAsset> {
    constructor(
        private dataSource: DataSource
    ) {
        super(AssignmentAsset, dataSource.createEntityManager());
    }
}

