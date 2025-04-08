import { Float, Parent, ResolveField, Resolver } from "@nestjs/graphql";
import { InfoBlock, OfficeLogs, OfficeUserPaycheck } from "@models/entities";
import { forwardRef, Inject } from "@nestjs/common";
import { OfficeInfoBlockRepo } from "@repositories/office-info-block.repo";
import { OfficeFeatureLogType, OfficeLogType } from "@enum/logs/logs.enum";
import { OfficeBlockType } from "@enum/block/block.enum";
import { cryptoAesStringDecode } from "@services/crypto-js/index.crypto-js";
import { OfficeUserPaycheckRepo } from "@models/repositories";

@Resolver(_of => OfficeUserPaycheck)
export class OfficeUserPaycheckFieldResolver {
    constructor(
        @Inject(forwardRef(() => OfficeInfoBlockRepo))
        private officeInfoBlockRepo: OfficeInfoBlockRepo,
        @Inject(forwardRef(() => OfficeUserPaycheckRepo))
        private userPaycheckRepo: OfficeUserPaycheckRepo
    ) {
    }

    @ResolveField('infoBlocks', _return => [InfoBlock], { nullable: true })
    async infoBlocks(
        @Parent() root: OfficeUserPaycheck
    ) {
        const _this = await OfficeUserPaycheck.findOne({
            relations: ['payroll'],
            where: {
                id: root.id
            }
        })

        let metadata = root.metadata

        if (root.encode) {
            metadata = this.userPaycheckRepo.metadataDecodeValue(root.metadata, root.user.id)
        }

        const blocks = await this.officeInfoBlockRepo.find({
            where: {
                relationType: OfficeBlockType.Payroll,
                relationId: _this.payroll?.id,
            },
            order: {
                order: "ASC"
            }
        })
        blocks.forEach(block => {
            block.officeUserExtraData = metadata && metadata[0] ? JSON.parse(metadata[0]) : null
        })
        return blocks
    }

    @ResolveField('currency', _return => String, { nullable: true })
    currency(){
        return "VNĐ"
    }

    @ResolveField('comments', _return => [OfficeLogs], { nullable: true })
    comments(
        @Parent() root: OfficeUserPaycheck
    ){
        return OfficeLogs.find({
            where: {
                featureLogType: OfficeFeatureLogType.Paycheck,
                featureLogId: root.id,
                type: OfficeLogType.Comment,
            },
            order: {
                createdAt: 'ASC'
            }
        })
    }

    @ResolveField('wage', _return => Float, { nullable: true })
    wage(
        @Parent() root: OfficeUserPaycheck
    ){
        if (!root.wage) return 0
        if (!root.encode) return parseInt(root.wage)

        return parseInt(cryptoAesStringDecode(root.wage, root.user.id))
    }
}