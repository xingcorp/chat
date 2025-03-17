import { Injectable } from "@nestjs/common";
import { DataSource, In, Repository } from "typeorm";
import { Viewer } from "@models/entities";
import { ViewerTypeEnum, ViewTypeEnum } from "@enum/viewer/viewer.enum";

@Injectable()
export class ViewerRepo extends Repository<Viewer> {
    constructor(private dataSource: DataSource) {
        super(Viewer, dataSource.createEntityManager());
    }

    async getBy(where: any, relations?: string[]) {
        const query = this.createQueryBuilder('qb')

        if (relations) {
            relations.map(i => query.leftJoinAndSelect(`qb.${i}`, `${i}`))
        }

        return query
            .where(where)
            .getOne()
    }

    async countViewerBy(where: any, relations?: string[]) {
        const query = this.createQueryBuilder('qb')

        if (relations) {
            relations.map(i => query.leftJoinAndSelect(`qb.${i}`, `${i}`))
        }

        return query
            .where(where)
            .getCount()
    }

    async countUnreadVersionWikiInListOfUser(versionIds: string[], userId: string) {
        const readCount = await this.createQueryBuilder()
            .where({
                relationType: ViewTypeEnum.VersionWiki,
                relationId: In(versionIds),
                viewerType: ViewerTypeEnum.User,
                viewerId: userId
            })
            .getCount()

        return versionIds.length - readCount
    }

    async isRequestReadThisVersionWiki(versionId: string, userId: string) {
        const readCount = await this.createQueryBuilder()
            .where({
                relationType: ViewTypeEnum.VersionWiki,
                relationId: versionId,
                viewerType: ViewerTypeEnum.User,
                viewerId: userId
            })
            .getCount()

        return !!readCount
    }
}