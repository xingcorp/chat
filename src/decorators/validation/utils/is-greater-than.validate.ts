import { ValidationArguments, ValidationOptions, ValidatorConstraint } from "class-validator";
import { baseRegisterDecorator, BaseValidateDecoratorConstraint } from "@decorators/validation/base.validate.decorator";

@ValidatorConstraint()
export class IsGreaterThanConstraint extends BaseValidateDecoratorConstraint {

    constructor() {
        super()
        this.messageKey = 'WrongDataInput'
    }

    async checkValidate(value: any, args: ValidationArguments) {
        const [name] = args.constraints;
        const property = (args.object as any)[name];
        return value > property
    }
}

export function IsGreaterThan(property: string, validationOptions?: ValidationOptions) {
    return function (object: Object, propertyName: string) {
        baseRegisterDecorator({
            name: 'IsGreaterThan',
            target: object.constructor,
            constraints: [property],
            propertyName: propertyName,
            options: validationOptions,
            validator: IsGreaterThanConstraint,
        });
    };
}