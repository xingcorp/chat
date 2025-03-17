import { Injectable } from "@nestjs/common";
import { DataSource, Repository } from "typeorm";
import { UserWorkProfileDetail } from "@models/entities";
import { RequestContext } from "@common/context/request.context";

@Injectable()
export class DetailWorkProfileRepo extends Repository<UserWorkProfileDetail> {
    constructor(private dataSource: DataSource) {
        super(UserWorkProfileDetail, dataSource.createEntityManager());
    }

    async getByWorkProfileId(id: string) {
        return this.findOne({
            relations: ['workProfile'],
            where: {
                workProfile: {id},
            }
        })
    }

    createNew(args: { metadata: JSON; major: string; userCode: string }) {
        return this.create({
            userCode: args.userCode,
            major: args.major,
            metadata: args.metadata,
            createdBy: RequestContext.currentRequestId() ?? null,
            updatedBy: RequestContext.currentRequestId() ?? null,
        })
    }

    async changeByWorkProfileId(id: string, args: { metadata?: JSON; major?: string; userCode?: string }) {
        const detail = await this.getByWorkProfileId(id)

        detail.userCode = args.userCode ?? detail.userCode
        detail.major = args.major ?? detail.major
        detail.metadata = {...detail.metadata, ...args.metadata}

        return detail
    }
}