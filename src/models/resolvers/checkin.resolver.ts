import { Int, Parent, ResolveField, Resolver } from "@nestjs/graphql";
import { CheckIn, CheckInDetail, OfficeUser } from "../entities";
import { MoreThan } from "typeorm";
import { CheckInInfo } from "src/modules/graphql/checkin/checkin.response";

@Resolver(_of => CheckIn)
export class CheckInFieldResolver {
    constructor() { }

    @ResolveField('checkInOwner', _return => OfficeUser, { nullable: true })
    async checkInOwner(
        @Parent() root: CheckIn
    ) {
        return OfficeUser.findOne({
            where: {
                iamUserId: root.createdBy
            }
        })
    }

    @ResolveField('checkInTime', _return => Int, { nullable: true })
    async checkInTime(@Parent() root: CheckIn) {
        const checkInDetail = await CheckInDetail.findOne({
            where: {
                checkInId: root.id
            },
            order: {
                order: "DESC"
            }
        })
        if (checkInDetail) return checkInDetail.order

        return null
    }

    @ResolveField('details', _return => [CheckInDetail], { nullable: true })
    async details(@Parent() root: CheckIn) {
        return CheckInDetail.find({
            where: {
                checkInId: root.id
            },
            order: {
                order: "ASC"
            }
        })
    }

    @ResolveField('checkInDetail', _return => CheckInDetail, { nullable: true })
    async checkInDetail(@Parent() root: CheckIn) {
        return CheckInDetail.findOne({
            where: {
                checkInId: root.id,
                order: 1
            }
        })
    }

    @ResolveField('checkOutDetail', _return => CheckInDetail, { nullable: true })
    async checkOutDetail(@Parent() root: CheckIn) {
        return CheckInDetail.findOne({
            where: {
                checkInId: root.id,
                order: MoreThan(1)
            },
            order: {
                order: "DESC"
            }
        })
    }

    @ResolveField('info', _return => CheckInInfo, { nullable: true })
    async info(@Parent() root: CheckIn) {
        const checkIn = await CheckInDetail.findOne({
            where: {
                checkInId: root.id,
                order: 1
            }
        })

        const checkOut = await CheckInDetail.findOne({
            where: {
                checkInId: root.id,
                order: MoreThan(1)
            },
            order: {
                order: "DESC"
            }
        })

        if (checkIn && checkOut) {
            const time = checkOut.createdAt.getTime() - checkIn.createdAt.getTime()

            return {
                workingTime: time,
                isValid: time >= Number(process.env.OFFICE_WORKING_TIME || 8*60*60*1000) ? true : false
            }
        }
        
        return {
            workingTime: 0,
            isValid: false
        }
    }
}