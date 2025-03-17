import { RequestContext } from "@common/context/request.context";
import { AddressLearningRepo } from "@models/repositories/learning/address.learning.repo";
import { Injectable } from "@nestjs/common";
import { LearningAddressCreateInput, LearningAddressUpdateInput, LearningAddressUpsertInput, AddressLearningFilterInput } from "./dto/address.learning.args";
import { OfficeError } from "@common/office.error";
@Injectable()
export class AddressLearningService {
    constructor(private readonly addressLearningRepo: AddressLearningRepo) {

    }

    async create(args: LearningAddressCreateInput) {
        const address = this.addressLearningRepo.create(args)

        address.orgChart = await RequestContext.getRootOrg()

        await address.save()

        return address;
    }

    async update(args: LearningAddressUpdateInput) {
        const address = args.address

        address.name = args.name

        await address.save()

        return address;
    }

    upsert(args: LearningAddressUpsertInput) {
        if (args.addressId) {
            return this.update(args)
        }

        return this.create(args)
    }

    get(id: string) {
        return this.addressLearningRepo.getBy({ id });
    }

    async list(filter: AddressLearningFilterInput) {
        const [data, total] = await this.addressLearningRepo.listByFilter(filter)

        return {
            total: total as number,
            count: data.length,
            records: data
        }
    }

    async remove(id: string) {
        const address = await this.addressLearningRepo.getBy({ id })

        if (!address) {
            throw OfficeError.LearningAddressNotFound
        }

        address.createdBy = RequestContext.currentRequestId()
        await address.save()
        await address.softRemove()

        return id;
    }
}