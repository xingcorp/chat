import {
    ValidationArguments,
    ValidationOptions,
    ValidatorConstraint,
} from "class-validator";
import { baseRegisterDecorator, BaseValidateDecoratorConstraint } from "@decorators/validation/base.validate.decorator";
import { Injectable } from "@nestjs/common";
import { BookingCarScheduleRepo } from "@models/repositories";
import { CarBookingRequest, RequestStatus } from "@models/entities/car.booking.request";

@ValidatorConstraint({ async: true })
@Injectable()
export class IsExistAndCanModifyScheduleCarDbValidateConstraint extends BaseValidateDecoratorConstraint {

    constructor(private readonly scheduleRepo: BookingCarScheduleRepo) {
        super()
        this.messageKey = 'BookingCarScheduleNotFound'
    }

    async checkValidate(id: string, args: ValidationArguments) {
        const data = await this.scheduleRepo.findOne({
            relations: ['booking'],
            where: {id}
        })

        if (!data) {
            this.messageKey = 'BookingCarScheduleNotFound'
            return false
        }

        const request = await CarBookingRequest.findOneBy({
            id: data.requestId
        })

        if (!request) {
            this.messageKey = 'BookingCarScheduleNotFound'
            return false
        }

        if (request.status !== RequestStatus.Approved) {
            this.messageKey = 'BookingCarNotApprovalCanNotChange'
        }

        if (data.startAt < new Date()) {
            this.messageKey = 'BookingCarCanNotChange'
            return false
        }

        if (data) this.getEntityById(args, data)

        return true
    }
}

export function IsExistAndCanModifyScheduleCarDbValidate(validationOptions?: ValidationOptions) {
    return function (object: Object, propertyName: string) {
        baseRegisterDecorator({
            name: 'IsExistAndCanModifyScheduleCarDbValidate',
            target: object.constructor,
            propertyName: propertyName,
            options: validationOptions,
            validator: IsExistAndCanModifyScheduleCarDbValidateConstraint,
        });
    };
}