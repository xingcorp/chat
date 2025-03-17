import { Parent, ResolveField, Resolver } from "@nestjs/graphql";
import { CheckIn, CheckInDetail, CheckInPlace, OfficeUser } from "../entities";

@Resolver(_of => CheckInDetail)
export class CheckInDetailFieldResolver {
    constructor() { }

    @ResolveField('checkInCode', _return => String, { nullable: true })
    async checkInCode(
        @Parent() root: CheckInDetail
    ) {
        const checkIn = await CheckIn.findOne({
            where: {
                id: root.checkInId
            }
        })
        if (checkIn) return checkIn.code

        return null
    }

    @ResolveField('checkInOwner', _return => OfficeUser, { nullable: true })
    async checkInOwner(
        @Parent() root: CheckInDetail
    ) {
        return OfficeUser.findOne({
            where: {
                iamUserId: root.createdBy
            }
        })
    }

    @ResolveField('checkInPlace', _return => CheckInPlace, { nullable: true })
    async checkInPlace(
        @Parent() root: CheckInDetail
    ) {
        return CheckInPlace.findOne({
            where: {
                id: root.placeId
            },
            withDeleted: true
        })
    }
}