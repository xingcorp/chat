import { Args, Mutation, Resolver } from '@nestjs/graphql';
import { ScheduleBookingCarService } from "@modules/graphql/management/car/schedule.booking.car.service";
import { SetMetadata, UseInterceptors } from "@nestjs/common";
import { ServiceActions, ServiceKeys, UserType } from "@core/middleware/guard/service.action";
import { FixedDataOrgChartUserAllAndWithChildInterceptor } from "@interceptors/org-chart.interceptor";
import { ErrorInterceptor } from "@interceptors/error.interceptor";
import {
    CarBookingScheduleRemoveInput,
    CarBookingScheduleUpdateInput
} from "@modules/graphql/management/car/dto/schedule.booking.car.args";
import { CarBookingSchedule } from "@models/entities/car.booking.schedule";

@Resolver()
export class ScheduleBookingCarResolver {

    constructor(private readonly scheduleBookingCarService: ScheduleBookingCarService) {
    }

    @Mutation(() => CarBookingSchedule, { name: 'managementCarBookingScheduleUpdate' })
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    @SetMetadata(ServiceKeys.UserType, [UserType.SYSTEM_USER])
    @UseInterceptors(FixedDataOrgChartUserAllAndWithChildInterceptor)
    @UseInterceptors(ErrorInterceptor)
    async managementCarBookingScheduleUpdate(
        @Args('arguments', { nullable: false }) args: CarBookingScheduleUpdateInput,
    ) {
        return this.scheduleBookingCarService.adminCarBookingScheduleUpdate(args)
    }

    @Mutation(() => String, { name: 'managementCarBookingScheduleRemove' })
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    @SetMetadata(ServiceKeys.UserType, [UserType.SYSTEM_USER])
    @UseInterceptors(FixedDataOrgChartUserAllAndWithChildInterceptor)
    @UseInterceptors(ErrorInterceptor)
    async managementCarBookingScheduleRemove(
        @Args('arguments', { nullable: false }) args: CarBookingScheduleRemoveInput,
    ) {
        return this.scheduleBookingCarService.adminCarBookingScheduleRemove(args)
    }

    /*User*/
    @Mutation(() => CarBookingSchedule, { name: 'officeCarBookingScheduleUpdate' })
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    @SetMetadata(ServiceKeys.UserType, [UserType.NORMAL_USER])
    @UseInterceptors(FixedDataOrgChartUserAllAndWithChildInterceptor)
    @UseInterceptors(ErrorInterceptor)
    async officeCarBookingScheduleUpdate(
        @Args('arguments', { nullable: false }) args: CarBookingScheduleUpdateInput,
    ) {
        return this.scheduleBookingCarService.userCarBookingScheduleUpdate(args)
    }

    @Mutation(() => String, { name: 'officeCarBookingScheduleRemove' })
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    @SetMetadata(ServiceKeys.UserType, [UserType.NORMAL_USER])
    @UseInterceptors(FixedDataOrgChartUserAllAndWithChildInterceptor)
    @UseInterceptors(ErrorInterceptor)
    async officeCarBookingScheduleRemove(
        @Args('arguments', { nullable: false }) args: CarBookingScheduleRemoveInput,
    ) {
        return this.scheduleBookingCarService.userCarBookingScheduleRemove(args)
    }
}
