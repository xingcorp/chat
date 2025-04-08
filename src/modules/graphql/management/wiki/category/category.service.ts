import { Injectable } from '@nestjs/common';
import {
    WikiCategoryCreateInput, WikiCategoryFilterInput,
    WikiCategoryUpdateInput, WikiCategoryUpsertInput
} from "@modules/graphql/management/wiki/dto/category.wiki.args";
import { RequestContext } from "@common/context/request.context";
import { CategoryWikiRepo } from "@models/repositories";
import { OfficeError } from "@common/office.error";

@Injectable()
export class CategoryService {
    constructor(private readonly categoryWikiRepo: CategoryWikiRepo) {
    }
    async create(args: WikiCategoryCreateInput) {
        const category = this.categoryWikiRepo.create(args)

        category.orgCharts = await RequestContext.getRootOrgs()

        await category.save()

        return category;
    }

    async update(args: WikiCategoryUpdateInput) {
        const category = args.categoryWiki

        category.name = args.name

        await category.save()

        return category;
    }

    upsert(args: WikiCategoryUpsertInput) {
        if (args.categoryWiki) {
            return this.update(args)
        }

        return this.create(args)
    }

    get(id: string) {
        return this.categoryWikiRepo.getOneBy({id});
    }

    async list(filter: WikiCategoryFilterInput) {
        const [data, total] = await this.categoryWikiRepo.listByFilter(filter)

        return {
            total: total as number,
            count: data.length,
            records: data
        }
    }

    async remove(id: string) {
        const category = await this.categoryWikiRepo.getOneBy({id}, ['wikis'])

        if (!category) {
            throw OfficeError.CategoryWikiNotFound
        }

        if (category.wikis.length) {
            throw OfficeError.CategoryWikiHaveWikiCanNotRemove
        }

        category.createdBy = RequestContext.currentRequestId()
        await category.save()
        await category.softRemove()

        return id;
    }
}
