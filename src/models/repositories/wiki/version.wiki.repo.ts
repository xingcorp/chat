import { Injectable } from "@nestjs/common";
import { DataSource, In, Not, Repository } from "typeorm";
import { DocumentWiki, VersionWiki } from "@models/entities";
import { WikiNewVersionCreateInput } from "@modules/graphql/management/wiki/dto/wiki.args";
import { RequestContext } from "@common/context/request.context";
import { UpdateTypeEnum, UpdateTypeNumberEnum, VersionWikiStatus } from "@enum/wiki/wiki.enum";

@Injectable()
export class VersionWikiRepo extends Repository<VersionWiki> {
    constructor(private dataSource: DataSource) {
        super(VersionWiki, dataSource.createEntityManager());
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

    createNew(param: { name: string; content: string; thumbnailIds: string[]; updateType?: UpdateTypeEnum; status: VersionWikiStatus }) {
        return this.create({
            ...param,
            createdBy: RequestContext.currentRequestId()
        })
    }

    async getLatestVersionOfWiki(id: string | undefined, relations?: string[]) {
        const query = this.createQueryBuilder('qb')

        if (relations) {
            relations.map(i => query.leftJoinAndSelect(`qb.${i}`, `${i}`))
        }

        return query
            .where({
                wiki: { id },
                isLatestVersion: true
            })
            .getOne()
    }

    async getAllLatestVersionOfListWikis(ids: string[], relations?: string[]) {
        const query = this.createQueryBuilder('qb')

        if (relations) {
            relations.map(i => query.leftJoinAndSelect(`qb.${i}`, `${i}`))
        }

        return query
            .where({
                wiki: { id: In(ids) },
                isLatestVersion: true
            })
            .getMany()
    }

    async getNewestVersionOfWiki(id: string | undefined, relations?: string[]) {
        const query = this.createQueryBuilder('qb')

        if (relations) {
            relations.map(i => query.leftJoinAndSelect(`qb.${i}`, `${i}`))
        }

        return query
            .where({
                wiki: { id },
            })
            .orderBy('qb."createdAt"', 'DESC')
            .getOne()
    }

    genFirstVersion(updateType: number) {
        let version = '1'

        for (let t = 1; t < updateType; t++) {
            version += '.0'
        }

        return version;
    }

    genFirstVersionDefault() {
        return '1.0.0';
    }

    genNextVersion(updateType: UpdateTypeEnum, lastVer: string) {
        const last = lastVer.split('.')
        const length = last.length
        let version = ''
        let updateTypeNumber = UpdateTypeNumberEnum[updateType]

        for (let i = 1; i <= length; i++) {
            if (i === updateTypeNumber) version += (+last[i - 1] + 1).toString() + '.'
            if (i < updateTypeNumber) version += last[i - 1] + '.'
        }

        version = version.slice(0, -1)
        if (updateTypeNumber < length) {
            for (let t = updateTypeNumber; t < length; t++) {
                version += '.0'
            }
        }

        return version;
    }

    async waitingApprovalGetByWikiId(wikiId: string) {
        return this.createQueryBuilder()
            .where({
                wiki: {
                    id: wikiId
                },
                status: In([VersionWikiStatus.UnderReview, VersionWikiStatus.Pending])
            })
            .getOne()
    }

    async waitingApprovalGetById(versionWikiId: string) {
        return this.createQueryBuilder()
            .where({
                id: versionWikiId,
                status: In([VersionWikiStatus.UnderReview, VersionWikiStatus.Pending])
            })
            .getOne()
    }

    async setLatestVersion(version: VersionWiki) {
        await this.update(
            {
                id: Not(version.id),
                wiki: {id: version.wiki.id},
            },
            {
                isLatestVersion: false
            }
        )

        version.isLatestVersion = true
    }

    async updateLatestVersion(version: VersionWiki) {
        await this.setLatestVersion(version)

        await version.save()
    }

    async getWaitToApprovalOfWiki(id: string) {
        return this.createQueryBuilder()
            .where({
                wiki: {id},
                status: In([VersionWikiStatus.UnderReview, VersionWikiStatus.Pending])
            })
            .getMany()
    }
}