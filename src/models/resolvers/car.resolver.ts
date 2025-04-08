import { Parent, ResolveField, Resolver } from "@nestjs/graphql"
import { CarBookingRequest } from "../entities/car.booking.request"
import { Car } from "../entities/car"
import { ApprovalForm, OfficeOrgChart, OfficeUser } from "../entities"

@Resolver(_of => Car)
export class CarFieldResolver {
    constructor() { }

    @ResolveField('driver', _return => OfficeUser, { nullable: true })
    async driver(
        @Parent() root: Car
    ) {
        if (root.driverId) {
            return OfficeUser.findOne({
                where: {
                    id: root.driverId
                }
            })
        }

        return null
    }

    @ResolveField('approvalForm', _return => ApprovalForm, { nullable: true })
    async approvalForm(
        @Parent() root: Car
    ) {
        if (root.approvalFormId) {
            return ApprovalForm.findOne({
                where: {
                    id: root.approvalFormId
                }
            })
        }

        return null
    }

    @ResolveField('orgChart', _return => OfficeOrgChart, { nullable: true })
    async orgChart(
        @Parent() root: Car
    ) {
        if (root.orgChartId) {
            return OfficeOrgChart.findOne({
                where: {
                    id: root.orgChartId
                }
            })
        }

        return null
    }
}