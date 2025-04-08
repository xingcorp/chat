import { Injectable } from "@nestjs/common";
import { DataSource, Repository } from "typeorm";
import { OfficeChatMessageReader } from "@models/entities";

@Injectable()
export class ChatMessageReaderRepo extends Repository<OfficeChatMessageReader> {
    constructor(private dataSource: DataSource) {
        super(OfficeChatMessageReader, dataSource.createEntityManager());
    }
}