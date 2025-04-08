import { Int, Parent, ResolveField, Resolver } from "@nestjs/graphql";
import { OfficeOrgChart, OfficeUser } from "../entities";
import { ObjectStatus } from "../entities/profile.info.block";

@Resolver(_of => OfficeOrgChart)
export class OrgChartFieldResolver {
    constructor() { }

    @ResolveField('parent', _return => OfficeOrgChart, { nullable: true })
    async parentOrg(
        @Parent() root: OfficeOrgChart
    ) {
        if (root.parentId !== 'root') {
            return OfficeOrgChart.findOne({
                where: {
                    id: root.parentId
                }
            })
        }

        return null
    }

    @ResolveField('level', _return => Int, { nullable: true })
    async level(
        @Parent() root: OfficeOrgChart
    ) {
        const elements = root.path.split("/")

        return elements && elements.length > 1 ? elements.length - 1 : null
    }

    @ResolveField('companyId', _return => String, { nullable: true })
    async companyId(
        @Parent() root: OfficeOrgChart
    ) {
        const elements = root.path.split("/")

        return elements[1]
    }

    @ResolveField('approver', _return => OfficeUser, { nullable: true })
    async approver(
        @Parent() root: OfficeOrgChart
    ) {
        if (root.approverId) {
            return OfficeUser.findOne({
                where: {
                    id: root.approverId,
                    status: ObjectStatus.Active
                }
            })
        }

        return null
    }
}