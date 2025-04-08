import { Injectable } from '@nestjs/common';
import {
    ApprovalFormGroupCreateInput, ApprovalFormGroupCreateUpdateInput, ApprovalFormGroupFilter
} from "@modules/graphql/management/approval/approval-from-group/dto/approval-form-group.args";
import { ApprovalFormGroupRepo, ApprovalFormRepo, OfficeOrgChartRepo } from "@models/repositories";
import { RequestContext } from "@common/context/request.context";
import { OfficeError } from "@common/office.error";

@Injectable()
export class ApprovalFromGroupService {

    constructor(
        private readonly formGroupRepo: ApprovalFormGroupRepo,
        private readonly orgChartRepo: OfficeOrgChartRepo,
        private readonly formRepo: ApprovalFormRepo,
    ) {
    }

    async create(args: ApprovalFormGroupCreateInput) {
        const group = this.formGroupRepo.create(args)

        group.orgCharts = await RequestContext.getRootOrgs()

        await group.save()

        return group;
    }

    async update(args: ApprovalFormGroupCreateUpdateInput) {
        const group = args.formGroup

        group.name = args.name

        await group.save()
        await group.reload()

        return group;
    }

    get(id: string) {
        return this.formGroupRepo.getOneBy({id});
    }

    async list(filter: ApprovalFormGroupFilter) {
        const [data, total] = await this.formGroupRepo.listByFilter(filter)

        return {
            total: total as number,
            count: data.length,
            records: data
        }
    }

    async remove(id: string) {
        const group = await this.formGroupRepo.getOneBy({id}, ['forms'])

        if (!group) {
            throw OfficeError.ApprovalFormGroupNotExist
        }

        if (group.forms.length) {
            throw OfficeError.ApprovalFormGroupHaveFormCanNotRemove
        }

        await group.softRemove()

        return id;
    }

    async genGroupDefault() {
        const name = 'Nhóm phê duyệt'
        const check = await this.formGroupRepo.find()

        if (check.length) return

        const roots = await this.orgChartRepo.getAllRoot()

        for (const root of roots) {
            const group = this.formGroupRepo.create({name: name})

            const departmentIds = await this.orgChartRepo.getAllIdsCurrentAndChild([root.id])
            const forms = await this.formRepo.getAllOfDepartmentIds(departmentIds)

            group.orgCharts = [root]
            group.forms = forms

            await group.save()
        }
    }
}
