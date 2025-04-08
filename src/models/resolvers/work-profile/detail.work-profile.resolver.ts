import { Parent, ResolveField, Resolver } from "@nestjs/graphql";
import { InfoBlock, UserWorkProfileDetail } from "@models/entities";
import { OfficeBlockType } from "@enum/block/block.enum";
import { RequestContext } from "@common/context/request.context";
import { OfficeOrgChartRepo } from "@models/repositories";

@Resolver(_of => UserWorkProfileDetail)
export class DetailWorkProfileResolver {

    constructor(private readonly orgChartRepo: OfficeOrgChartRepo) {
    }

    @ResolveField('infoBlocks', _return => [InfoBlock], { nullable: true })
    async infoBlocks(
        @Parent() root: UserWorkProfileDetail
    ) {
        const org = await this.orgChartRepo.getRootOfDepartmentId(root.department.id)

        const blocks = await InfoBlock.find({
            where: {
                relationType: OfficeBlockType.WorkProfile,
                relationId: org?.id
            },
            order: {
                order: "ASC"
            }
        })

        const metadata = root?.metadata ?? null
        blocks.forEach(block => {
            block.officeUserExtraData = metadata
        })
        return blocks
    }
}
