import { Parent, ResolveField, Resolver } from "@nestjs/graphql";
import { InfoBlock, OfficePayroll } from "@models/entities";
import { forwardRef, Inject } from "@nestjs/common";
import { OfficeInfoBlockRepo } from "@repositories/office-info-block.repo";

@Resolver(_of => OfficePayroll)
export class OfficePayrollFieldResolver {
    constructor(
        @Inject(forwardRef(() => OfficeInfoBlockRepo))
        private officeInfoBlockRepo: OfficeInfoBlockRepo,
    ) {
    }

    @ResolveField('blocks', _return => [InfoBlock], {nullable: true})
    async blocks(
        @Parent() root: OfficePayroll
    ) {
        return this.officeInfoBlockRepo.findPayrollBlocksBy({
            relationId: root.id,
        })
    }
}