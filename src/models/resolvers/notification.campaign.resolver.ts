import { Int, Parent, ResolveField, Resolver } from "@nestjs/graphql";
import { OfficeTitle, OfficeOrgChart } from "../entities";
import { In } from "typeorm";
import { NotificationCampaign } from "@models/entities/notification.campaign";

@Resolver(_of => NotificationCampaign)
export class NotificationCampaignFieldResolver {
    constructor() { }

    @ResolveField('departments', _return => [OfficeOrgChart], { nullable: true })
    async departments(
        @Parent() root: NotificationCampaign
    ) {
        if (root.departmentIds) {
            return OfficeOrgChart.find({
                where: {
                    id: In(root.departmentIds)
                }
            })
        }

        return null
    }

    @ResolveField('titles', _return => [OfficeTitle], { nullable: true })
    async titles(
        @Parent() root: NotificationCampaign
    ) {
        if (root.titleIds) {
            return OfficeTitle.find({
                where: { id: In(root.titleIds) }
            })
        }
        return null
    }

    @ResolveField('startTimeInMinutes', _return => String, { nullable: true })
    async startTimeInMinutes(
        @Parent() root: NotificationCampaign
    ) {
        if (root.startTimeIn) {
            return root.startTimeIn.map(time=> `${Math.floor(time / 60)}:${time % 60}`).join(',');
        }

        if (root.startTimeInMinutes) {
            return `${Math.floor(root.startTimeInMinutes / 60)}:${root.startTimeInMinutes % 60}`
        }

        return null
    }
}