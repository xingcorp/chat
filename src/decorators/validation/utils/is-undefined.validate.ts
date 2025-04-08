import {
    registerDecorator, ValidationArguments,
    ValidationOptions,
    ValidatorConstraint,
} from "class-validator";
import { baseRegisterDecorator, BaseValidateDecoratorConstraint } from "@decorators/validation/base.validate.decorator";


@ValidatorConstraint()
export class IsUndefinedValidateConstraint extends BaseValidateDecoratorConstraint {

    constructor() {
        super()
        this.messageKey = 'DataFound'
    }

    async checkValidate(value: any, args: ValidationArguments) {
        return !value;
    }
}

export function IsUndefinedValidate(validationOptions?: ValidationOptions) {
    return function (object: Object, propertyName: string) {
        baseRegisterDecorator({
            name: 'IsUndefinedValidate',
            target: object.constructor,
            propertyName: propertyName,
            options: validationOptions,
            validator: IsUndefinedValidateConstraint,
        });
    };
}