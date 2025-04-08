import { OfficeOrgChart, OfficeTitle, UserDepartment } from "@models/entities";
import { Parent, ResolveField, Resolver } from "@nestjs/graphql";

@Resolver(_of => UserDepartment)
export class UserDepartmentFieldResolver {
    constructor() { }

    @ResolveField('department', _return => OfficeOrgChart, { nullable: true })
    async department(
        @Parent() root: UserDepartment
    ) {
        if (root.departmentId) {
            return OfficeOrgChart.findOne({
                where: { id: root.departmentId }
            })
        }
        return null
    }

    @ResolveField('title', _return => OfficeTitle, { nullable: true })
    async title(
        @Parent() root: UserDepartment
    ) {
        if (root.titleId) {
            return OfficeTitle.findOne({
                where: { id: root.titleId }
            })
        }
        return null
    }
}