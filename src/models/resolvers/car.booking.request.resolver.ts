import { Parent, ResolveField, Resolver } from "@nestjs/graphql"
import { CarBookingRequest } from "../entities/car.booking.request"
import { OfficeApproval, OfficeSysUser, OfficeUser } from "../entities"
import { Car } from "../entities/car"
import { In } from "typeorm";
import { getDataAdminToImpersonationUser } from "@helpers/data.helper";

@Resolver(_of => CarBookingRequest)
export class CarBookingRequestFieldResolver {
    constructor() { }

    @ResolveField('bookingApproval', _return => OfficeApproval, { nullable: true })
    async bookingApproval(
        @Parent() root: CarBookingRequest
    ) {
        if (root.approvalId) {
            return OfficeApproval.findOne({
                where: {
                    id: root.approvalId
                }
            })
        }

        return null
    }

    @ResolveField('car', _return => Car, { nullable: true })
    async car(
        @Parent() root: CarBookingRequest
    ) {
        if (root.carId) {
            return Car.findOne({
                where: {
                    id: root.carId
                }
            })
        }

        return null
    }

    @ResolveField('requester', _return => OfficeUser, { nullable: true })
    async requester(
        @Parent() root: CarBookingRequest
    ) {
        const user = await OfficeUser.findOne({
            where: {
                id: root.createdBy
            }
        })
        if (user) return user

        const admin = await OfficeSysUser.findOneBy({
            id: In([root.createdBy])
        })

        if (!admin) return null

        return {
            ...getDataAdminToImpersonationUser(admin)
        } as OfficeUser
    }
}