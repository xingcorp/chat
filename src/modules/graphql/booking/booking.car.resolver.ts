import { SetMetadata } from "@nestjs/common";
import { Args, Mutation, Query, Resolver } from "@nestjs/graphql";
import { ServiceActions, ServiceKeys } from "../../core/middleware/guard/service.action";
import { BookCarArgs, BookingCarFilter, ResponseBookingCarArgs } from "./dto/booking.args";
import { OfficeRequester, OfficeRequesterId } from "../../core/middleware/decorator/user.decorator";
import { BookingCarResponse, BookingsCarResponse } from "./dto/booking.response";
import { BookingCar, BookingCarProgress } from "../../../models/entities/booking/booking.car";
import { OfficeUser } from "../../../models/entities";
import { BookingService } from "./booking.service";
import { BaseError } from "../../core/core.error";
import { OfficeError } from "../../../common/office.error";
import { Brackets } from "typeorm";

@Resolver()
export class BookingCarResolver {
    constructor(
        private readonly bookingService: BookingService
    ) { }

    @Query(_return => BookingsCarResponse, { name: "officeGetBookingCarSchedule" })
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    async getAllMeeting(
        @Args("filter") filter: BookingCarFilter,
        @OfficeRequesterId() officeRequesterId: string,
    ): Promise<BookingsCarResponse> {
        const page = filter.page ? (filter.page - 1) : 0
        const size = filter.size ? filter.size : 20

        let query = BookingCar.createQueryBuilder('booking')
            .where(new Brackets(db => {
                db.where({ bookedById: officeRequesterId })
                    .orWhere({ leaderId: officeRequesterId })
                    .orWhere({ adminId: officeRequesterId })
            }))
            .leftJoinAndSelect('booking.bookedBy', 'bookedBy')
            .leftJoinAndSelect('booking.leader', 'leader')
            .leftJoinAndSelect('booking.admin', 'admin')
            .skip(page * size)
            .take(size)

        if (filter.progress) {
            query = query.andWhere('booking.progress = :progress', { progress: filter.progress })
        }
        const [bookings, total] = await query.getManyAndCount()
        return {
            total,
            count: bookings.length,
            bookings
        }
    }

    @Mutation(() => BookingCarResponse, { name: 'officeBookCar' })
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    async bookCar(
        @Args('arguments', { nullable: false }) args: BookCarArgs,
        @OfficeRequester() officeRequester: OfficeUser,
    ): Promise<BookingCarResponse> {
        const approver = await OfficeUser.findOne({
            where: { id: args.leaderId }
        })
        if (!approver) {
            throw new BaseError('Office.EmployeeNotFound', 'Không tìm thấy trưởng bộ phận phê duyệt')
        }
        const booking = await BookingCar.create({
            ...args,
            leader: approver,
            startAt: new Date(args.startAt),
            endAt: new Date(args.endAt),
            bookedBy: officeRequester,
        }).save()

        return { booking }
    }

    @Mutation(() => BookingCarResponse, { name: 'officeUpdateBookingByLeader' })
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    async updateBookingByLeader(
        @Args('arguments', { nullable: false }) args: ResponseBookingCarArgs,
        @OfficeRequesterId() officeRequesterId: string,
    ) {
        const booking = await BookingCar.findOne({ where: { id: args.bookingId } })
        if (!booking) {
            throw OfficeError.BookingCarNotFound
        }
        if (booking.progress != BookingCarProgress.Waiting_For_Approval) {
            throw OfficeError.ActionNotAllowed()
        }
        if (booking.leaderId != officeRequesterId) {
            throw new BaseError('Office.EmployeeNotFound', 'Bạn không có quyền thực hiện!')
        }
        booking.noteFromLeader = args.note;
        booking.progress = args.isApprove ? BookingCarProgress.Leader_Approve : BookingCarProgress.Reject;
        await booking.save()

        return { booking }
    }

    @Mutation(() => BookingCarResponse, { name: 'officeUpdateBookingByAdmin' })
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    async updateBookingByAdmin(
        @Args('arguments', { nullable: false }) args: ResponseBookingCarArgs,
        @OfficeRequesterId() officeRequesterId: string,
    ) {
        const booking = await BookingCar.findOne({ where: { id: args.bookingId } })
        if (!booking) {
            throw OfficeError.BookingCarNotFound
        }
        if (booking.progress != BookingCarProgress.Leader_Approve) {
            throw OfficeError.ActionNotAllowed()
        }
        if (booking.adminId != officeRequesterId) {
            throw new BaseError('Office.EmployeeNotFound', 'Bạn không có quyền thực hiện!')
        }
        booking.noteFromAdmin = args.note;
        booking.progress = args.isApprove ? BookingCarProgress.Approve : BookingCarProgress.Reject;
        await booking.save()

        return { booking }
    }
}