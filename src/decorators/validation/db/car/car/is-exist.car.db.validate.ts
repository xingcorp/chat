import {
    ValidationArguments,
    ValidationOptions,
    ValidatorConstraint,
} from "class-validator";
import { baseRegisterDecorator, BaseValidateDecoratorConstraint } from "@decorators/validation/base.validate.decorator";
import { Injectable } from "@nestjs/common";
import { CarRepo } from "@models/repositories";

@ValidatorConstraint({ async: true })
@Injectable()
export class IsExistCarDbValidateConstraint extends BaseValidateDecoratorConstraint {

    constructor(private readonly carRepo: CarRepo) {
        super()
        this.messageKey = 'OfficeCarNotExisted'
    }

    async checkValidate(id: string, args: ValidationArguments) {
        const data = await this.carRepo.getById(id)

        if (data) this.getEntityById(args, data)

        return !!data
    }
}

export function IsExistCarDbValidate(validationOptions?: ValidationOptions) {
    return function (object: Object, propertyName: string) {
        baseRegisterDecorator({
            name: 'IsExistCarDbValidate',
            target: object.constructor,
            propertyName: propertyName,
            options: validationOptions,
            validator: IsExistCarDbValidateConstraint,
        });
    };
}