import {
    registerDecorator, ValidationArguments,
    ValidationOptions,
    ValidatorConstraint,
} from "class-validator";
import { baseRegisterDecorator, BaseValidateDecoratorConstraint } from "@decorators/validation/base.validate.decorator";
import validator, { isDate } from "validator";
import { datetimeGetDateFromFormat } from "@utils/datetime.utils";


@ValidatorConstraint()
export class IsValidDateFormatValidateConstraint extends BaseValidateDecoratorConstraint {

    constructor() {
        super()
    }

    async checkValidate(value: any, args: ValidationArguments) {
        const [format] = args.constraints;

        const valid = isDate(value, { format: format })

        if (valid) await this.getDate(value, args, format)

        return valid
    }

    private async getDate(value: any, args: ValidationArguments, format: string) {
        const propertyAt = args.property.split('Date')
        propertyAt.pop()
        args.object[propertyAt.join('Date') + 'At'] = datetimeGetDateFromFormat(format, value).getTime()
    }
}

export function IsValidDateFormatValidate(format: string ,validationOptions?: ValidationOptions) {
    return function (object: Object, propertyName: string) {
        baseRegisterDecorator({
            name: 'IsValidDateFormatValidate',
            target: object.constructor,
            constraints: [format],
            propertyName: propertyName,
            options: validationOptions,
            validator: IsValidDateFormatValidateConstraint,
        });
    };
}