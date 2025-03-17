import { Parent, ResolveField, Resolver } from "@nestjs/graphql";
import { ApprovalForm, MeetingRoom, OfficeOrgChart } from "../entities";
import { RedisService } from "../../modules/core/common/redis.service";

@Resolver(_of => MeetingRoom)
export class MeetingRoomFieldResolver {
    constructor(
        private readonly redisService: RedisService
    ) { }

    @ResolveField('orgChart', _return => OfficeOrgChart, { nullable: true })
    async orgChart(@Parent() root: MeetingRoom) {
        if (root.organizationId) {
            try {
                // const redisKey = `orgChart_${root.organizationId}`
                // const cached = await this.redisService.get(redisKey)
                // if (cached) {
                //     return JSON.parse(cached)
                // }

                // await this.redisService.setWithTtl(redisKey, org ? JSON.stringify(org) : null, 1 * 60) // 1 minutes
                console.log(root.organizationId)
                return await OfficeOrgChart.findOne({
                    where: { id: root.organizationId },
                    withDeleted: true
                })
            } catch (error) {
                console.log(`[MeetingRoomFieldResolver] Get orgChart has error: ${error}`)
            }
        }
    }

    @ResolveField('approvalForm', _return => ApprovalForm, { nullable: true })
    async approvalForm(
        @Parent() root: MeetingRoom
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
}