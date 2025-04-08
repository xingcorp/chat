import { Injectable } from '@nestjs/common';
import { CertificateLearningRepo } from "@models/repositories";
import { RequestContext } from "@common/context/request.context";
import { OfficeError } from "@common/office.error";
import {
    LearningCertificateCreateInput, LearningCertificateFilterInput,
    LearningCertificateUpdateInput, LearningCertificateUpsertInput
} from "@modules/graphql/learning/certificate/dto/certificate.learning.arg";

@Injectable()
export class CertificateLearningService {
    constructor(private readonly certificateLearningRepo: CertificateLearningRepo) {
    }

    async create(args: LearningCertificateCreateInput) {
        const entity = this.certificateLearningRepo.create(args)

        entity.orgChart = await RequestContext.getRootOrg()

        await entity.save()

        return entity;
    }

    async update(args: LearningCertificateUpdateInput) {
        const entity = args.certificate

        entity.name = args.name

        await entity.save()

        return entity;
    }

    upsert(args: LearningCertificateUpsertInput) {
        if (args.certificateId) {
            return this.update(args)
        }

        return this.create(args)
    }

    get(id: string) {
        return this.certificateLearningRepo.getBy({id});
    }

    async list(filter: LearningCertificateFilterInput) {
        const [data, total] = await this.certificateLearningRepo.listByFilter(filter)

        return {
            total: total as number,
            count: data.length,
            records: data
        }
    }

    async remove(id: string) {
        const skill = await this.certificateLearningRepo.getBy({id})

        if (!skill) {
            throw OfficeError.LearningCertificateNotFound
        }

        skill.createdBy = RequestContext.currentRequestId()
        await skill.save()
        await skill.softRemove()

        return id;
    }
}
