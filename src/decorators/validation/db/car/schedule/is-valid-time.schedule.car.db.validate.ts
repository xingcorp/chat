import {
    ValidationArguments,
    ValidationOptions,
    ValidatorConstraint,
} from "class-validator";
import { baseRegisterDecorator, BaseValidateDecoratorConstraint } from "@decorators/validation/base.validate.decorator";
import { Injectable } from "@nestjs/common";
import { BookingCarScheduleRepo } from "@models/repositories";
import { In, LessThan, MoreThan, Not } from "typeorm";
import { RequestStatus } from "@models/entities/car.booking.request";

@ValidatorConstraint({ async: true })
@Injectable()
export class IsValidTimeScheduleCarDbValidateConstraint extends BaseValidateDecoratorConstraint {

    constructor(private readonly scheduleRepo: BookingCarScheduleRepo) {
        super()
        this.messageKey = 'BookingCarNotAvailable'
    }

    async checkValidate(id: string, args: ValidationArguments) {
        const schedules = await this.scheduleRepo.find({
            where: {
                id: Not(id),
                startAt: LessThan(new Date(args.object['endAt'])),
                endAt: MoreThan(new Date(args.object['startAt'])),
                carId: args.object['carId'],
                booking: {
                    status: In([RequestStatus.UnderReview, RequestStatus.Approved])
                }
            }
        })

        return !schedules.length
    }
}

export function IsValidTimeScheduleCarDbValidate(validationOptions?: ValidationOptions) {
    return function (object: Object, propertyName: string) {
        baseRegisterDecorator({
            name: 'IsValidTimeScheduleCarDbValidate',
            target: object.constructor,
            propertyName: propertyName,
            options: validationOptions,
            validator: IsValidTimeScheduleCarDbValidateConstraint,
        });
    };
}