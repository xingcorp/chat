import { Injectable } from '@nestjs/common';
import {
    DocumentTagCreateInput, DocumentTagFilterInput,
    DocumentTagUpdateInput,
    DocumentTagUpsertInput
} from "@modules/graphql/management/document/dto/tag.args";
import { TagDocumentRepo } from "@models/repositories";
import { RequestContext } from "@common/context/request.context";
import { OfficeError } from "@common/office.error";

@Injectable()
export class TagService {

    constructor(private readonly tagDocumentRepo: TagDocumentRepo) {
    }

    async create(args: DocumentTagCreateInput) {
        const tag = this.tagDocumentRepo.create(args)

        tag.orgCharts = await RequestContext.getRootOrgs()

        await tag.save()

        return tag;
    }

    async update(args: DocumentTagUpdateInput) {
        const tag = args.tag

        tag.name = args.name

        await tag.save()

        return tag;
    }

    upsert(args: DocumentTagUpsertInput) {
        if (args.tag) {
            return this.update(args)
        }

        return this.create(args)
    }

    get(id: string) {
        return this.tagDocumentRepo.getOneBy({id});
    }

    async list(filter: DocumentTagFilterInput) {
        const [data, total] = await this.tagDocumentRepo.listByFilter(filter)

        return {
            total: total as number,
            count: data.length,
            records: data
        }
    }

    async remove(id: string) {
        const tag = await this.tagDocumentRepo.getOneBy({id}, ['wikis'])

        if (!tag) {
            throw OfficeError.TagDocumentNotFound
        }

        if (tag.wikis.length) {
            throw OfficeError.TagDocumentHaveWikiCanNotRemove
        }

        tag.createdBy = RequestContext.currentRequestId()
        await tag.save()
        await tag.softRemove()

        return id;
    }
}
