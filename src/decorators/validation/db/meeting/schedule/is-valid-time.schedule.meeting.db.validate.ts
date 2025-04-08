import {
    ValidationArguments,
    ValidationOptions,
    ValidatorConstraint,
} from "class-validator";
import { baseRegisterDecorator, BaseValidateDecoratorConstraint } from "@decorators/validation/base.validate.decorator";
import { Injectable } from "@nestjs/common";
import { MeetingRoomScheduleRepo } from "@models/repositories";
import { In, LessThan, MoreThan, Not } from "typeorm";
import { RequestStatus } from "@models/entities/car.booking.request";

@ValidatorConstraint({ async: true })
@Injectable()
export class IsValidTimeScheduleMeetingDbValidateConstraint extends BaseValidateDecoratorConstraint {

    constructor(private readonly scheduleRepo: MeetingRoomScheduleRepo) {
        super()
        this.messageKey = 'BookingRoomNotAvailable'
    }

    async checkValidate(id: string, args: ValidationArguments) {
        const schedules = await this.scheduleRepo.find({
            where: {
                id: Not(id),
                startAt: LessThan(new Date(args.object['endAt'])),
                endAt: MoreThan(new Date(args.object['startAt'])),
                meetingRoomId: args.object['meetingRoomId'],
                booking: {
                    status: In([RequestStatus.UnderReview, RequestStatus.Approved])
                }
            }
        })

        return !schedules.length
    }
}

export function IsValidTimeScheduleMeetingDbValidate(validationOptions?: ValidationOptions) {
    return function (object: Object, propertyName: string) {
        baseRegisterDecorator({
            name: 'IsValidTimeScheduleMeetingDbValidate',
            target: object.constructor,
            propertyName: propertyName,
            options: validationOptions,
            validator: IsValidTimeScheduleMeetingDbValidateConstraint,
        });
    };
}