import { Parent, ResolveField, Resolver } from "@nestjs/graphql";
import { OfficeWorkingShift, OfficeWorkingShiftDetail, UserAddress } from "@models/entities";
import { AddressType } from "@models/entities/profile.address";
import { InjectRepository } from "@nestjs/typeorm";
import { Repository } from "typeorm";

@Resolver(_of => OfficeWorkingShift)
export class WorkingShiftResolver {
    constructor (
        @InjectRepository(OfficeWorkingShift)
        private workingShiftRepository: Repository<OfficeWorkingShift>,
    ) { }

    @ResolveField('detail', _return => OfficeWorkingShiftDetail, { nullable: false })
    async detail(
        @Parent() root: OfficeWorkingShift
    ) {
        const shift = await this.workingShiftRepository.findOne({
            relations: ['detail'],
            where: {
                id: root.id
            }
        })
        return shift.detail
    }
}