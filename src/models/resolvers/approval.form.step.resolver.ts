import { Parent, ResolveField, Resolver } from "@nestjs/graphql";
import { ApprovalForm, ApprovalFormField, ApprovalFormStep, OfficeOrgChart, OfficeUser } from "../entities";
import { In } from "typeorm";

@Resolver(_of => ApprovalFormStep)
export class ApprovalFormStepFieldResolver {
    constructor() { }

    @ResolveField('consentUsers', _return => [OfficeUser], { nullable: true })
    async consentUsers(
        @Parent() root: ApprovalFormStep
    ) {
        if (root.consentBy) {
            return OfficeUser.find({
                where: {
                    id: In(root.consentBy)
                }
            })
        }

        return null
    }

    @ResolveField('approvers', _return => [OfficeUser], { nullable: true })
    async approver(
        @Parent() root: ApprovalFormStep
    ) {
        if (root.approveBy) {
            return OfficeUser.find({
                where: {
                    id: In(root.approveBy)
                }
            })
        }

        return null
    }

    @ResolveField('department', _return => OfficeOrgChart, { nullable: true })
    async department(
        @Parent() root: ApprovalFormStep
    ) {
        if (root.departmentId) {
            return OfficeOrgChart.findOne({
                where: {
                    id: root.departmentId
                }
            })
        }

        return null
    }
}