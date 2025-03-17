import { Parent, ResolveField, Resolver } from "@nestjs/graphql"
import { CarBookingSchedule } from "../entities/car.booking.schedule"
import { CarBookingRequest } from "../entities/car.booking.request"
import { Car } from "../entities/car"

@Resolver(_of => CarBookingSchedule)
export class CarBookingScheduleFieldResolver {
    constructor() { }

    @ResolveField('bookingRequest', _return => CarBookingRequest, { nullable: true })
    async bookingRequest(
        @Parent() root: CarBookingSchedule
    ) {
        if (root.requestId) {
            return CarBookingRequest.findOne({
                where: {
                    id: root.requestId
                }
            })
        }

        return null
    }

    @ResolveField('car', _return => Car, { nullable: true })
    async car(
        @Parent() root: CarBookingSchedule
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
}