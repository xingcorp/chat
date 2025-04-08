import {
    ValidationArguments,
    ValidationOptions,
    ValidatorConstraint,
} from "class-validator";
import { baseRegisterDecorator, BaseValidateDecoratorConstraint } from "@decorators/validation/base.validate.decorator";
import { Injectable } from "@nestjs/common";
import { MeetingRoomScheduleRepo } from "@models/repositories";

@ValidatorConstraint({ async: true })
@Injectable()
export class IsExistScheduleMeetingDbValidateConstraint extends BaseValidateDecoratorConstraint {

    constructor(private readonly scheduleRepo: MeetingRoomScheduleRepo) {
        super()
        this.messageKey = 'BookingRoomScheduleNotFound'
    }

    async checkValidate(id: string, args: ValidationArguments) {
        const data = await this.scheduleRepo.findOne({
            relations: ['booking'],
            where: {id}
        })

        if (data) this.getEntityById(args, data)

        return !!data
    }
}

export function IsExistScheduleMeetingDbValidate(validationOptions?: ValidationOptions) {
    return function (object: Object, propertyName: string) {
        baseRegisterDecorator({
            name: 'IsExistScheduleMeetingDbValidate',
            target: object.constructor,
            propertyName: propertyName,
            options: validationOptions,
            validator: IsExistScheduleMeetingDbValidateConstraint,
        });
    };
}