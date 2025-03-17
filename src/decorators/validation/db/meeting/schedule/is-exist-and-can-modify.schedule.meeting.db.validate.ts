import {
    ValidationArguments,
    ValidationOptions,
    ValidatorConstraint,
} from "class-validator";
import { baseRegisterDecorator, BaseValidateDecoratorConstraint } from "@decorators/validation/base.validate.decorator";
import { Injectable } from "@nestjs/common";
import { MeetingRoomScheduleRepo } from "@models/repositories";
import { RequestStatus } from "@models/entities/car.booking.request";

@ValidatorConstraint({ async: true })
@Injectable()
export class IsExistAndCanModifyScheduleMeetingDbValidateConstraint extends BaseValidateDecoratorConstraint {

    constructor(private readonly scheduleRepo: MeetingRoomScheduleRepo) {
        super()
        this.messageKey = 'BookingRoomScheduleNotFound'
    }

    async checkValidate(id: string, args: ValidationArguments) {
        const data = await this.scheduleRepo.findOne({
            relations: ['booking'],
            where: {id}
        })

        if (!data) {
            this.messageKey = 'BookingRoomScheduleNotFound'
            return false
        }

        if (data.booking.status !== RequestStatus.Approved) {
            this.messageKey = 'BookingRoomNotApprovalCanNotChange'
        }

        if (data.startAt < new Date()) {
            this.messageKey = 'BookingRoomCanNotChange'
            return false
        }

        if (data) this.getEntityById(args, data)

        return true
    }
}

export function IsExistAndCanModifyScheduleMeetingDbValidate(validationOptions?: ValidationOptions) {
    return function (object: Object, propertyName: string) {
        baseRegisterDecorator({
            name: 'IsExistAndCanModifyScheduleMeetingDbValidate',
            target: object.constructor,
            propertyName: propertyName,
            options: validationOptions,
            validator: IsExistAndCanModifyScheduleMeetingDbValidateConstraint,
        });
    };
}