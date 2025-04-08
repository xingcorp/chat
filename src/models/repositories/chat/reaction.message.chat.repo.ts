import { Injectable } from "@nestjs/common";
import { DataSource, Repository } from "typeorm";
import { OfficeChatMessageReaction } from "@models/entities";

@Injectable()
export class ReactionMessageChatRepo extends Repository<OfficeChatMessageReaction> {
    constructor(private dataSource: DataSource) {
        super(OfficeChatMessageReaction, dataSource.createEntityManager());
    }
}