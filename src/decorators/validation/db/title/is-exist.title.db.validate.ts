import {
    ValidationArguments,
    ValidationOptions,
    ValidatorConstraint,
} from "class-validator";
import { OfficeTitle } from "@models/entities";
import { baseRegisterDecorator, BaseValidateDecoratorConstraint } from "@decorators/validation/base.validate.decorator";
import { Injectable } from "@nestjs/common";

@ValidatorConstraint({ async: true })
@Injectable()
export class IsExistTitleDbValidateConstraint extends BaseValidateDecoratorConstraint {

    constructor() {
        super()
        this.messageKey = 'OrgTitleNotFound'
    }

    async checkValidate(id: string, args: ValidationArguments) {
        return (await OfficeTitle.find()).map(i => i.id).includes(id)
    }
}

export function IsExistTitleDbValidate(validationOptions?: ValidationOptions) {
    return function (object: Object, propertyName: string) {
        baseRegisterDecorator({
            name: 'IsExistTitleDbValidate',
            target: object.constructor,
            propertyName: propertyName,
            options: validationOptions,
            validator: IsExistTitleDbValidateConstraint,
        });
    };
}