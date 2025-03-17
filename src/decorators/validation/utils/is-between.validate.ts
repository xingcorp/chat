import { ValidationArguments, ValidationOptions, ValidatorConstraint } from "class-validator";
import { baseRegisterDecorator, BaseValidateDecoratorConstraint } from "@decorators/validation/base.validate.decorator";

@ValidatorConstraint()
export class IsBetweenConstraint extends BaseValidateDecoratorConstraint {

    constructor() {
        super()
        this.messageKey = 'WrongDataInput'
    }

    async checkValidate(value: any, args: ValidationArguments) {
        const [lowName, highName] = args.constraints;
        const low = (args.object as any)[lowName];
        const high = (args.object as any)[highName];
        return value > low && value < high
    }
}

export function IsBetween(lowestProperty: string, highestProperty: string, validationOptions?: ValidationOptions) {
    return function (object: Object, propertyName: string) {
        baseRegisterDecorator({
            name: 'IsBetween',
            target: object.constructor,
            propertyName: propertyName,
            constraints: [lowestProperty, highestProperty],
            options: validationOptions,
            validator: IsBetweenConstraint,
        });
    };
}