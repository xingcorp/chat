import {
    registerDecorator, ValidationArguments,
    ValidationOptions,
    ValidatorConstraint,
} from "class-validator";
import { baseRegisterDecorator, BaseValidateDecoratorConstraint } from "@decorators/validation/base.validate.decorator";


@ValidatorConstraint()
export class IsUndefinedAnotherValidateConstraint extends BaseValidateDecoratorConstraint {

    constructor() {
        super()
        this.messageKey = 'DataFound'
    }

    async checkValidate(value: any, args: ValidationArguments) {
        const [name] = args.constraints;
        const property = (args.object as any)[name];

        return !property;
    }
}

export function IsUndefinedAnotherValidate(property: string, validationOptions?: ValidationOptions) {
    return function (object: Object, propertyName: string) {
        baseRegisterDecorator({
            name: 'IsUndefinedAnotherValidate',
            target: object.constructor,
            constraints: [property],
            propertyName: propertyName,
            options: validationOptions,
            validator: IsUndefinedAnotherValidateConstraint,
        });
    };
}