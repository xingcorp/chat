import { Parent, ResolveField, Resolver } from "@nestjs/graphql";
import {
    ApprovalForm,
    ApprovalFormField,
    ApprovalFormGroup,
    ApprovalFormStep,
    OfficeOrgChart,
    OfficeUser,
    OrgChartApprovalForm
} from "../entities";
import { In } from "typeorm";
import { ObjectScope } from "../entities/approval.form";

@Resolver(_of => ApprovalForm)
export class ApprovalFormFieldResolver {
    constructor() { }

    @ResolveField('subcribers', _return => [OfficeUser], { nullable: true })
    async subcribers(
        @Parent() root: ApprovalForm
    ) {
        if (root.subscriberIds) {
            return OfficeUser.find({
                where: {
                    id: In(root.subscriberIds)
                }
            })
        }

        return null
    }

    @ResolveField('fields', _return => [ApprovalFormField], { nullable: true })
    async fields(
        @Parent() root: ApprovalForm
    ) {
        return ApprovalFormField.find({
            where: {
                formId: root.id
            },
            order: {
                order: "ASC"
            }
        })
    }

    @ResolveField('steps', _return => [ApprovalFormStep], { nullable: true })
    async steps(
        @Parent() root: ApprovalForm
    ) {
        return ApprovalFormStep.find({
            where: {
                formId: root.id
            },
            order: {
                order: "ASC"
            }
        })
    }

    @ResolveField('departments', _return => [OfficeOrgChart], { nullable: true })
    async departments(
        @Parent() root: ApprovalForm
    ) {
        if (root.scope === ObjectScope.Common) return null
        const relations = await OrgChartApprovalForm.find({
            where: {
                formId: root.id
            }
        })
        return OfficeOrgChart.find({
            where: {
                id: In(relations.map(r => r.departmentId))
            }
        })
    }

    @ResolveField('groups', _return => [ApprovalFormGroup], { nullable: true })
    async groups(
        @Parent() root: ApprovalForm
    ) {
        const _this = await ApprovalForm.findOne({
            relations: ['groups'],
            where: {id: root.id}
        })

        return _this.groups
    }
}