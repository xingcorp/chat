import {
    ValidationArguments,
    ValidationOptions,
    ValidatorConstraint,
} from "class-validator";
import { baseRegisterDecorator, BaseValidateDecoratorConstraint } from "@decorators/validation/base.validate.decorator";
import { Injectable } from "@nestjs/common";
import { TitleRepo } from "@models/repositories";

@ValidatorConstraint({ async: true })
@Injectable()
export class IsCodeExistTitleDbValidateConstraint extends BaseValidateDecoratorConstraint {

    constructor(private readonly titleRepo: TitleRepo) {
        super()
        this.messageKey = 'OrgTitleNotFound'
    }

    async checkValidate(code: string, args: ValidationArguments) {
        return this.titleRepo.checkValidBy({code})
    }
}

export function IsCodeExistTitleDbValidate(validationOptions?: ValidationOptions) {
    return function (object: Object, propertyName: string) {
        baseRegisterDecorator({
            name: 'IsCodeExistTitleDbValidate',
            target: object.constructor,
            propertyName: propertyName,
            options: validationOptions,
            validator: IsCodeExistTitleDbValidateConstraint,
        });
    };
}