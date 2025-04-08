import {
    registerDecorator, ValidationArguments,
    ValidationOptions,
    ValidatorConstraint,
} from "class-validator";
import { baseRegisterDecorator, BaseValidateDecoratorConstraint } from "@decorators/validation/base.validate.decorator";


@ValidatorConstraint()
export class IsDefinedValidateConstraint extends BaseValidateDecoratorConstraint {

    constructor() {
        super()
    }

    async checkValidate(value: any, args: ValidationArguments) {
        if (Array.isArray(value)) return !!value.length

        return typeof value !== 'undefined' && value !== null;
    }
}

export function IsDefinedValidate(validationOptions?: ValidationOptions) {
    return function (object: Object, propertyName: string) {
        baseRegisterDecorator({
            name: 'IsDefinedValidate',
            target: object.constructor,
            propertyName: propertyName,
            options: validationOptions,
            validator: IsDefinedValidateConstraint,
        });
    };
}