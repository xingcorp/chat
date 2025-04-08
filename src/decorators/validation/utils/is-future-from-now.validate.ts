import {
    registerDecorator, ValidationArguments,
    ValidationOptions,
    ValidatorConstraint,
} from "class-validator";
import { baseRegisterDecorator, BaseValidateDecoratorConstraint } from "@decorators/validation/base.validate.decorator";


@ValidatorConstraint()
export class IsFutureFromNowConstraint extends BaseValidateDecoratorConstraint {

    constructor() {
        super()
        this.messageKey = 'NotInThePastDate'
    }

    async checkValidate(date: Number, args: ValidationArguments) {
        return Date.now() < date;
    }
}

export function IsFutureFromNow(validationOptions?: ValidationOptions) {
    return function (object: Object, propertyName: string) {
        baseRegisterDecorator({
            name: 'IsFutureFromNow',
            target: object.constructor,
            propertyName: propertyName,
            options: validationOptions,
            validator: IsFutureFromNowConstraint,
        });
    };
}