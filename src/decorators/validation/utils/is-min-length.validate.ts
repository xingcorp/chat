import { ValidationArguments, ValidationOptions, ValidatorConstraint } from "class-validator";
import { baseRegisterDecorator, BaseValidateDecoratorConstraint } from "@decorators/validation/base.validate.decorator";

@ValidatorConstraint()
export class IsMinLengthValidateConstraint extends BaseValidateDecoratorConstraint {

    constructor() {
        super()
        this.messageKey = 'WrongDataInput'
    }

    async checkValidate(value: any, args: ValidationArguments) {
        const [length] = args.constraints;

        return value.length >= parseInt(length)
    }
}

export function IsMinLengthValidate(property: number, validationOptions?: ValidationOptions) {
    return function (object: Object, propertyName: string) {
        baseRegisterDecorator({
            name: 'IsMinLengthValidate',
            target: object.constructor,
            constraints: [property],
            propertyName: propertyName,
            options: validationOptions,
            validator: IsMinLengthValidateConstraint,
        });
    };
}