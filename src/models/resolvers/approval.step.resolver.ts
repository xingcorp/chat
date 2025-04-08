import { Float, Parent, ResolveField, Resolver } from "@nestjs/graphql"
import { ApprovalStep, OfficeSysUser, OfficeUser } from "../entities"
import { ILike, In } from "typeorm"
import { ApprovalTableRow } from "../entities/approval.table.row"
import { getDataAdminToImpersonationUser } from "@helpers/data.helper";

@Resolver(_of => ApprovalStep)
export class ApprovalStepFieldResolver {
    constructor() { }

    @ResolveField('consentUsers', _return => [OfficeUser], { nullable: true })
    async consentUsers(
        @Parent() root: ApprovalStep
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
        @Parent() root: ApprovalStep
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

    @ResolveField('actionUser', _return => OfficeUser, { nullable: true })
    async actionUser(
        @Parent() root: ApprovalStep
    ) {
        if (root.actionBy) {
            const user = await OfficeUser.findOne({
                where: [
                    { id: root.actionBy },
                    { iamUserId: root.actionBy },
                    { iamUserUsedIds: ILike(`%${root.actionBy}%`) },
                ]
            })

            if (!user) {
                const admin = await OfficeSysUser.findOneBy({ id: root.actionBy })

                if (!admin) return null

                return {
                    ...getDataAdminToImpersonationUser(admin)
                } as OfficeUser
            }

            return user
        }

        return null
    }

    @ResolveField('actionAt', _return => Float, { nullable: true })
    async actionAt(
        @Parent() root: ApprovalStep
    ) {
        return root.actionBy ? root.actionAt : null
    }

    @ResolveField('approvedRows', _return => [ApprovalTableRow], { nullable: true })
    async tableRows(
        @Parent() root: ApprovalStep
    ) {
        return ApprovalTableRow.find({
            where: {
                actionStepId: root.id
            }
        })
    }
}