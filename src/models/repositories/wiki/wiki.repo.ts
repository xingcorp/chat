import { Injectable } from "@nestjs/common";
import { DataSource, ILike, In, Not, ObjectLiteral, Repository } from "typeorm";
import { DocumentWiki, OrgChartDocument, VersionWiki } from "@models/entities";
import { SelectQueryBuilder } from "typeorm/query-builder/SelectQueryBuilder";
import { WikiFilter } from "../../../arguments/wiki/args.wiki";
import { OrdinalCase } from "@common/enum.common";
import { RequestContext } from "@common/context/request.context";
import { BRIDGE_TABLE_DB_OBJ } from "@common/db/bridge-table.db";
import { DocumentType, ObjectEffect } from "@models/entities/org.chart.document";
import { WikiStatus } from "@enum/wiki/wiki.enum";

@Injectable()
export class WikiRepo extends Repository<DocumentWiki> {
    constructor(private dataSource: DataSource) {
        super(DocumentWiki, dataSource.createEntityManager());
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

    async getManyBy(where: any, relations?: string[]) {
        const query = this.createQueryBuilder('qb')

        if (relations) {
            relations.map(i => query.leftJoinAndSelect(`qb.${i}`, `${i}`))
        }

        return query
            .where(where)
            .getMany()
    }

    async getAllOfFolderByFolderId(folderId: string) {
        return this.createQueryBuilder()
            .where({folder: {id: folderId}})
            .getMany()
    }

    async getAllOfFoldersByFolderIds(folderIds: string[]) {
        const where = {
            folder: {id: In(folderIds)}
        }

        if (RequestContext.isNormalUser()) {
            where['isPublic'] = Not(false)
        }

        const query = this
            .createQueryBuilder()
            .where(where)

        return query.getMany()
    }

    async getAllNameStartOfFolderByFolderId(folderId: string, name: string) {
        const where = {
            folder: {id: folderId}
        }

        if (RequestContext.isNormalUser()) {
            where['isPublic'] = Not(false)
        }

        const query = this
            .createQueryBuilder()
            .where({
                name: ILike(`${name}%`)
            })

        return query.getMany()
    }

    async getById(id: string, folderIds: string[]) {
        const query = this.createQueryBuilder('qb')
            .leftJoinAndSelect(`qb.versions`, `versions`)
            .leftJoinAndSelect(`qb.folder`, `folder`)
            .leftJoinAndSelect(`qb.tags`, `tags`)
            .where({
                id,
                folder: {id: In(folderIds || [])},
                status: Not(WikiStatus.Inactive)
            })

        if (RequestContext.isNormalUser()) {
            query.andWhere({status: Not(WikiStatus.Inactive)})
        }

        return query.getOne()
    }

    async listByFilter(filter: WikiFilter, folderIds: string[]) {
        const query = this.createQueryBuilder('qb')
            .leftJoinAndSelect('qb.versions', 'versions')
            .leftJoinAndSelect('qb.folder', 'folder')
            .leftJoinAndSelect(
                BRIDGE_TABLE_DB_OBJ.WIKI_DOCUMENT_TAG.name,
                'wBridgeOrg',
                `"wBridgeOrg"."${BRIDGE_TABLE_DB_OBJ.WIKI_DOCUMENT_TAG.inverseJoinColumn.name}" = qb.id`)
            .leftJoinAndMapOne('qb.latest', VersionWiki, 'latest', 'latest."wikiId"::text = qb."id"::text AND latest."isLatestVersion" IS TRUE')
            .where({
                folder: {id: In(folderIds ?? [])}
            })
            // .orderBy('qb.createdAt', 'DESC')

        if (RequestContext.isNormalUser()) {
            const denyIds = await OrgChartDocument.find({
                where: {
                    userId: await RequestContext.currentId(),
                    type: DocumentType.Wiki,
                    effect: ObjectEffect.Deny
                }
            })

            query
                .andWhere(`qb."isPublic" IS TRUE`)
                .andWhere({status: Not(WikiStatus.Inactive)})
                .andWhere({
                    id: Not(In(denyIds.map(i => i?.documentId) ?? []))
                })
        }

        if (filter) await this.filterQuery(query, filter)

        return query.getManyAndCount()
    }

    private async filterQuery(query: SelectQueryBuilder<DocumentWiki>, filter: WikiFilter) {
        /*default get all*/
        if (filter.page || filter.size) {
            filter.size = filter.size ? filter.size : 20 //1
            filter.page = filter.page ? (filter.page - 1) : 0

            query.take(filter.size)
                .skip(filter.page * filter.size)
        }

        if (filter && filter.ordinal) {
            switch (filter.ordinal) {
                case OrdinalCase.Asc:
                    query.orderBy('qb.createdAt', 'ASC')
                    break
                case OrdinalCase.Desc:
                    query.orderBy('qb.createdAt', 'DESC')
                    break
                case OrdinalCase.NameAsc:
                    query.orderBy('qb."name"', 'ASC')
                    break
                case OrdinalCase.NameDesc:
                    query.orderBy('qb."name"', 'DESC')
                    break
                case OrdinalCase.ViewerDesc:
                    query.orderBy('qb.viewCount', 'DESC')
                    break
                case OrdinalCase.ViewerAsc:
                    query.orderBy('qb.viewCount', 'ASC')
                    break
            }
        }

        if (filter && filter.keyword) {
            /*query.andWhere(new Brackets(db => {
                db.where(`unaccent(LOWER(qb.name)) ILIKE unaccent(LOWER(:keyword))`, {keyword: `%${filter.keyword.trim()}%`})
                    .orWhere(`unaccent(LOWER(qb.code)) ILIKE unaccent(LOWER(:keyword))`, {keyword: `%${filter.keyword.trim()}%`})
                    .orWhere(`unaccent(LOWER(qb.serial)) ILIKE unaccent(LOWER(:keyword))`, {keyword: `%${filter.keyword.trim()}%`})
            }))*/
        }

        if (filter && filter.folderIds && filter.folderIds.length) {
            query.andWhere({
                folder: {id: In(filter.folderIds)}
            })
        }

        if (filter && filter.importants && filter.importants.length) {
            query.andWhere({
                important: In(filter.importants)
            })
                .orderBy('qb.createdAt', 'DESC')
        }

        if (filter && filter.tagIds && filter.tagIds.length) {
            query.andWhere(
                `"wBridgeOrg"."${BRIDGE_TABLE_DB_OBJ.WIKI_DOCUMENT_TAG.joinColumn.name}" in (:...tagIds)`,
                {tagIds: filter.tagIds})
        }

    }

    async updateLatestVersion(versionWiki: ObjectLiteral | VersionWiki) {
        const wiki = await this.getBy({id: versionWiki?.wiki?.id})

        wiki.isPublic = true
        wiki.name = versionWiki?.name ?? wiki.name
        wiki.code = versionWiki?.code ?? wiki.code
        wiki.tags = versionWiki?.tags ?? wiki.tags
        wiki.updatedAt = versionWiki?.updatedAt ?? new Date()
        wiki.viewCount = 0

        await wiki.save()

        return wiki
    }

    softRemoveAllOfFolderIds(folderIds: string[]) {
        return this.createQueryBuilder()
            .softDelete()
            .where({
                folder: {
                    id: In(folderIds)
                }
            })
    }

    async getAllOfOrgByIds(ids: string[]) {
        return this.createQueryBuilder('qb')
            .leftJoinAndSelect(`qb.orgCharts`, `orgCharts`)
            .where({
                orgCharts: {id: In(ids)}
            })
            .getMany()
    }
}