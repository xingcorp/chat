import { Injectable } from '@nestjs/common';
import {
    LearningSkillCreateInput, LearningSkillFilterInput,
    LearningSkillUpdateInput, LearningSkillUpsertInput
} from "@modules/graphql/learning/skill/dto/skill.learning.arg";
import { RequestContext } from "@common/context/request.context";
import { SkillLearningRepo } from "@models/repositories";
import { OfficeError } from "@common/office.error";

@Injectable()
export class SkillLearningService {

    constructor(private readonly skillLearningRepo: SkillLearningRepo) {
    }

    async create(args: LearningSkillCreateInput) {
        const skill = this.skillLearningRepo.create(args)

        skill.orgChart = await RequestContext.getRootOrg()

        await skill.save()

        return skill;
    }

    async update(args: LearningSkillUpdateInput) {
        const skill = args.skill

        skill.name = args.name

        await skill.save()

        return skill;
    }

    upsert(args: LearningSkillUpsertInput) {
        if (args.skillId) {
            return this.update(args)
        }

        return this.create(args)
    }

    get(id: string) {
        return this.skillLearningRepo.getBy({id});
    }

    async list(filter: LearningSkillFilterInput) {
        const [data, total] = await this.skillLearningRepo.listByFilter(filter)

        return {
            total: total as number,
            count: data.length,
            records: data
        }
    }

    async remove(id: string) {
        const skill = await this.skillLearningRepo.getBy({id})

        if (!skill) {
            throw OfficeError.LearningSkillNotFound
        }

        skill.createdBy = RequestContext.currentRequestId()
        await skill.save()
        await skill.softRemove()

        return id;
    }
}
