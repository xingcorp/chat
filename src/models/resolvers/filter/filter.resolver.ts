import { Parent, ResolveField, Resolver } from "@nestjs/graphql";
import { ApprovalForm, OfficeFilter, OfficeOrgChart, OfficeUser } from "@models/entities";
import { FilterRelationType } from "@enum/filter/filter.enum";
import { In } from "typeorm";
import { arrayConvertToDistinctAndNotNull } from "@utils/array.utils";
import GraphQLJSON from "graphql-type-json";

@Resolver(_of => OfficeFilter)
export class FilterResolver {

    constructor() {
    }

    @ResolveField('creators', _return => [OfficeUser], {nullable: true})
    async creators(
        @Parent() root: OfficeFilter
    ) {
        if (root.relationType === FilterRelationType.UserApproval) {
            return OfficeUser.find({
                where: {
                    id: In(arrayConvertToDistinctAndNotNull(root?.filter?.creatorIds ?? []))
                }
            })
        }

        return null
    }

    @ResolveField('departments', _return => [OfficeOrgChart], {nullable: true})
    async departments(
        @Parent() root: OfficeFilter
    ) {
        if (root.relationType === FilterRelationType.UserApproval) {
            return OfficeOrgChart.find({
                where: {
                    id: In(arrayConvertToDistinctAndNotNull(root?.filter?.departmentIds ?? []))
                }
            })
        }

        return null
    }

    @ResolveField('approvals', _return => [OfficeUser], {nullable: true})
    async approvals(
        @Parent() root: OfficeFilter
    ) {
        if (root.relationType === FilterRelationType.UserApproval) {
            return OfficeUser.find({
                where: {
                    id: In(arrayConvertToDistinctAndNotNull(root?.filter?.approvalIds ?? []))
                }
            })
        }

        return null
    }

    @ResolveField('forms', _return => [ApprovalForm], {nullable: true})
    async forms(
        @Parent() root: OfficeFilter
    ) {
        if (root.relationType === FilterRelationType.UserApproval) {
            return ApprovalForm.find({
                where: {
                    id: In(arrayConvertToDistinctAndNotNull(root?.filter?.formIds ?? []))
                }
            })
        }

        return null
    }

    @ResolveField('dataExplains', _return => GraphQLJSON, {nullable: true})
    async dataExplains(
        @Parent() root: OfficeFilter
    ) {
        switch (root.relationType) {
            case FilterRelationType.Task:
                return {
                    task: await this.dataExplainsTask(root)
                }
        }

        return null
    }

    private async dataExplainsTask(root: OfficeFilter) {
        return {
            creators: await OfficeUser.find({
                where: {
                    id: In(arrayConvertToDistinctAndNotNull(root?.filter?.creatorIds ?? []))
                }
            }),
            reporters: await OfficeUser.find({
                where: {
                    id: In(arrayConvertToDistinctAndNotNull(root?.filter?.reportedIds ?? []))
                }
            }),
            assignees: await OfficeUser.find({
                where: {
                    id: In(arrayConvertToDistinctAndNotNull(root?.filter?.assignedIds ?? []))
                }
            }),
            watchers: await OfficeUser.find({
                where: {
                    id: In(arrayConvertToDistinctAndNotNull(root?.filter?.watchersIds ?? []))
                }
            }),
        }
    }
}