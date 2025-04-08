import { registerDecorator, ValidationArguments, ValidationOptions, ValidatorConstraint } from "class-validator";
import { baseRegisterDecorator, BaseValidateDecoratorConstraint } from "@decorators/validation/base.validate.decorator";


@ValidatorConstraint()
export class IsGreaterThanOrEqualConstraint extends BaseValidateDecoratorConstraint {

    constructor() {
        super()
        this.messageKey = 'WrongDataInput'
    }

    async checkValidate(value: any, args: ValidationArguments) {
        const [name] = args.constraints;
        const property = (args.object as any)[name];
        return value >= property
    }
}

export function IsGreaterThanOrEqual(property: string, validationOptions?: ValidationOptions) {
    return function (object: Object, propertyName: string) {
        baseRegisterDecorator({
            name: 'IsGreaterThanOrEqual',
            target: object.constructor,
            propertyName: propertyName,
            constraints: [property],
            options: validationOptions,
            validator: IsGreaterThanOrEqualConstraint,
        });
    };
}