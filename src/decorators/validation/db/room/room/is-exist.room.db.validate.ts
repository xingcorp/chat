import {
    ValidationArguments,
    ValidationOptions,
    ValidatorConstraint,
} from "class-validator";
import { baseRegisterDecorator, BaseValidateDecoratorConstraint } from "@decorators/validation/base.validate.decorator";
import { Injectable } from "@nestjs/common";
import { MeetingRoom } from "@models/entities";

@ValidatorConstraint({ async: true })
@Injectable()
export class IsExistRoomDbValidateConstraint extends BaseValidateDecoratorConstraint {

    constructor() {
        super()
        this.messageKey = 'MeetingRoomNotFound'
    }

    async checkValidate(id: string, args: ValidationArguments) {
        const data = await MeetingRoom.findOne({ where: { id } });

        if (data) this.getEntityById(args, data)

        return !!data
    }
}

export function IsExistRoomDbValidate(validationOptions?: ValidationOptions) {
    return function (object: Object, propertyName: string) {
        baseRegisterDecorator({
            name: 'IsExistRoomDbValidate',
            target: object.constructor,
            propertyName: propertyName,
            options: validationOptions,
            validator: IsExistRoomDbValidateConstraint,
        });
    };
}