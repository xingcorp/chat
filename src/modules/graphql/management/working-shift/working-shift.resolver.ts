import { Args, Mutation, Resolver } from '@nestjs/graphql';
import { OfficeWorkingShift } from "@models/entities";
import { SetMetadata, UseInterceptors } from "@nestjs/common";
import { ServiceActions, ServiceKeys, UserType } from "@core/middleware/guard/service.action";
import { AddEmployeeArgs } from "@modules/graphql/management/employee/employee.args";
import { BearerAccessToken } from "@core/middleware/decorator/request.decorator";
import { RequesterId } from "@core/middleware/decorator/user.decorator";
import { WorkingShiftService } from "@modules/graphql/management/working-shift/working-shift.service";
import { WorkingShiftInput } from "@modules/graphql/management/working-shift/dto/working-shift.args";
import { ErrorInterceptor } from "@interceptors/error.interceptor";

@Resolver()
@UseInterceptors(ErrorInterceptor)
export class WorkingShiftResolver {

    constructor(
        private readonly workingShiftService: WorkingShiftService,
    ) { }

    // @Mutation(() => OfficeWorkingShift, { name: 'managementAddShift', nullable: true })
    // @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    // @SetMetadata(ServiceKeys.UserType, [UserType.SYSTEM_USER])
    async managementAddShift(
        @Args('arguments', { nullable: false }) args: WorkingShiftInput,
        @RequesterId() requesterId: string,
    ): Promise<OfficeWorkingShift> {
        console.log(args)
        return this.workingShiftService.createNewShift(args, requesterId)
    }
}
