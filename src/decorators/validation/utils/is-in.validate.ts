import {
    registerDecorator, ValidationArguments,
    ValidationOptions,
    ValidatorConstraint,
} from "class-validator";
import { baseRegisterDecorator, BaseValidateDecoratorConstraint } from "@decorators/validation/base.validate.decorator";


@ValidatorConstraint()
export class IsInValidateConstraint extends BaseValidateDecoratorConstraint {

    constructor() {
        super()
    }

    async checkValidate(value: any, args: ValidationArguments) {
        const [arr] = args.constraints;

        if (!Array.isArray(arr)) return false

        return arr.includes(value)
    }
}

export function IsInValidate(arr: any[] ,validationOptions?: ValidationOptions) {
    return function (object: Object, propertyName: string) {
        baseRegisterDecorator({
            name: 'IsInValidate',
            target: object.constructor,
            constraints: [arr],
            propertyName: propertyName,
            options: validationOptions,
            validator: IsInValidateConstraint,
        });
    };
}