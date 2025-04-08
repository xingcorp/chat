import { Args, Mutation, Query, Resolver } from "@nestjs/graphql";
import { Car } from "src/models/entities/car";
import { ServiceActions, ServiceKeys, UserType } from "src/modules/core/middleware/guard/service.action";
import { forwardRef, Inject, SetMetadata, UseInterceptors } from "@nestjs/common";
import { OfficeRequesterId, RequesterId } from "src/modules/core/middleware/decorator/user.decorator";
import { CarBookingScheduleFilter, EditOfficeCarArgs, OfficeActiveCarFilter, OfficeBookingCarArgs, OfficeCarArgs, OfficeCarFilter } from "./dto/car.args";
import { ApprovalForm, OfficeOrgChart, OfficeUser } from "src/models/entities";
import { OfficeError } from "src/common/office.error";
import { CarBookingScheduleResponse, CarResponse } from "./dto/car.response";
import { CarBookingRequest, RequestStatus } from "src/models/entities/car.booking.request";
import { CarService } from "./car.service";
import { CarBookingSchedule } from "src/models/entities/car.booking.schedule";
import {
    FixedDataOrgChartUserAllAndWithChildInterceptor,
    FixedDataOrgChartUserAllInterceptor, FixedDataOrgChartUserWithParentAndChildInterceptor
} from "@interceptors/org-chart.interceptor";
import { ErrorInterceptor } from "@interceptors/error.interceptor";

@Resolver()
export class CarResolver {
    constructor(
        @Inject(forwardRef(() => CarService))
        private readonly carService: CarService,
    ) { }

    @Mutation(() => Car, { name: 'officeAddCar' })
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    @SetMetadata(ServiceKeys.UserType, [UserType.SYSTEM_USER])
    async officeAddCar(
        @Args('arguments', { nullable: false }) args: OfficeCarArgs,
        @RequesterId() requesterId: string,
    ): Promise<Car> {
        const driver = await OfficeUser.findOne({
            where: {
                id: args.driverId
            }
        })
        if (!driver) throw OfficeError.EmployeeNotFound

        const car = Car.create({
            model: args.model,
            capacity: args.capacity,
            plateNumber: args.plateNumber,
            driverId: args.driverId,
            color: args.color,
            status: args.status,
            createdBy: requesterId,
            updatedBy: requesterId
        })

        if (args.orgChartId) {
            const orgChart = await OfficeOrgChart.findOne({ where: { id: args.orgChartId } })
            if (!orgChart) throw OfficeError.OrgChartNotFound

            car.orgChartId = orgChart.id
        }

        if (args.approvalFormId) {
            const approvalForm = await ApprovalForm.findOne({ where: { id: args.approvalFormId } })
            if (!approvalForm) throw OfficeError.ApprovalFormNotFound

            car.approvalFormId = approvalForm.id
        }

        return car.save()
    }

    @Mutation(() => Car, { name: 'officeEditCar' })
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    @SetMetadata(ServiceKeys.UserType, [UserType.SYSTEM_USER])
    async officeEditCar(
        @Args('arguments', { nullable: false }) args: EditOfficeCarArgs,
        @RequesterId() requesterId: string,
    ): Promise<Car> {
        const existedCar = await Car.findOne({
            where: {
                id: args.id
            }
        })

        if (!existedCar) {
            throw OfficeError.OfficeCarNotExisted
        }

        existedCar.model = args.model ? args.model : existedCar.model
        existedCar.capacity = args.capacity ? args.capacity : existedCar.capacity
        existedCar.plateNumber = args.plateNumber ? args.plateNumber : existedCar.plateNumber
        existedCar.color = args.color ? args.color : existedCar.color
        existedCar.status = args.status ? args.status : existedCar.status

        if (args.orgChartId && args.orgChartId !== existedCar.orgChartId) {
            const orgChart = await OfficeOrgChart.findOne({ where: { id: args.orgChartId } })
            if (!orgChart) throw OfficeError.OrgChartNotFound

            existedCar.orgChartId = orgChart.id
        }

        if (args.driverId && args.driverId !== existedCar.driverId) {
            const driver = await OfficeUser.findOne({ where: { id: args.driverId } })
            if (!driver) throw OfficeError.EmployeeNotFound

            existedCar.driverId = driver.id
        }

        if (args.approvalFormId && args.approvalFormId !== existedCar.approvalFormId) {
            const approvalForm = await ApprovalForm.findOne({ where: { id: args.approvalFormId } })
            if (!approvalForm) throw OfficeError.ApprovalFormNotFound

            existedCar.approvalFormId = approvalForm.id

            //yêu cầu đặt xe chưa phê duyệt -> chuyển sang luồng phê duyệt mới
        } else {
            args.approvalFormId = null
        }

        existedCar.updatedBy = requesterId

        return existedCar.save()
    }

    @Query(_return => CarResponse, { name: "officeGetCars" })
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    @SetMetadata(ServiceKeys.UserType, [UserType.SYSTEM_USER])
    @UseInterceptors(FixedDataOrgChartUserAllAndWithChildInterceptor)
    async officeGetCars(
        @Args("filter", { nullable: true }) filter: OfficeCarFilter,
        @RequesterId() requesterId: string,
    ): Promise<CarResponse> {
        const [list, count] = await this.carService.officeGetCars(filter, requesterId)

        return {
            total: count,
            count: list.length,
            cars: list
        }
    }

    @Query(_return => CarResponse, { name: "officeGetActiveCars" })
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    // @SetMetadata(ServiceKeys.UserType, [UserType.NORMAL_USER])
    @UseInterceptors(FixedDataOrgChartUserWithParentAndChildInterceptor)
    async officeGetActiveCars(
        @Args("filter", { nullable: true }) filter: OfficeActiveCarFilter
    ): Promise<CarResponse> {
        return this.carService.officeGetActiveCars(filter)
    }

    @Mutation(_return => Car, { name: "officeRemoveCar" })
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    @SetMetadata(ServiceKeys.UserType, [UserType.SYSTEM_USER])
    async officeRemoveCar(
        @Args("id") id: string,
        @RequesterId() requesterId: string,
    ): Promise<Car> {
        const existedCar = await Car.findOne({
            where: { id: id }
        })

        if (!existedCar) throw OfficeError.OfficeTitleNotExisted

        //Mark delete lịch sử sử dụng xe
        await CarBookingRequest.softRemove(await CarBookingRequest.find({ where: { carId: existedCar.id } }))
        await CarBookingSchedule.softRemove(await CarBookingSchedule.find({ where: { carId: existedCar.id } }))

        existedCar.updatedBy = requesterId
        await existedCar.softRemove()

        return existedCar
    }


    @Mutation(() => CarBookingRequest, { name: 'officeCarBookingRequest' })
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    @SetMetadata(ServiceKeys.UserType, [UserType.SYSTEM_USER, UserType.NORMAL_USER])
    @UseInterceptors(FixedDataOrgChartUserAllInterceptor)
    @UseInterceptors(ErrorInterceptor)
    async officeCarBookingRequest(
        @Args('arguments', { nullable: false }) args: OfficeBookingCarArgs,
    ): Promise<CarBookingRequest> {
        return this.carService.officeCarBookingRequest(args)
    }

    @Query(_return => CarBookingSchedule, { name: "officeCarBookingGetSchedule" })
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    async officeCarBookingGetSchedule(
        @Args("id") id: string,
    ): Promise<CarBookingSchedule> {
        const schedule = await CarBookingSchedule.findOne({
            where: { id: id }
        })

        if (!schedule) throw OfficeError.OfficeCarBookingScheduleNotExisted

        return schedule
    }

    @Query(_return => CarBookingScheduleResponse, { name: "officeCarBookingGetScheduleList" })
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    // @SetMetadata(ServiceKeys.UserType, [UserType.NORMAL_USER])
    @UseInterceptors(FixedDataOrgChartUserAllAndWithChildInterceptor)
    async officeCarBookingGetScheduleList(
        @Args("filter", { nullable: true }) filter: CarBookingScheduleFilter,
    ): Promise<CarBookingScheduleResponse> {
        return this.carService.officeCarBookingGetScheduleList(filter)
    }
}