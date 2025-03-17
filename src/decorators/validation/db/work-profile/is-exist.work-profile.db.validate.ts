import {
    registerDecorator, ValidationArguments,
    ValidationOptions,
    ValidatorConstraint,
} from "class-validator";
import { WorkProfileRepo } from "@models/repositories";
import { baseRegisterDecorator, BaseValidateDecoratorConstraint } from "@decorators/validation/base.validate.decorator";
import { Injectable } from "@nestjs/common";

@ValidatorConstraint({async: true})
@Injectable()
export class IsExistWorkProfileDbValidateConstraint extends BaseValidateDecoratorConstraint {

    constructor(private readonly workProfileRepo: WorkProfileRepo) {
        super()
        this.messageKey = 'UserWorkProfileNotFound'
    }

    async checkValidate(id: string, args: ValidationArguments) {
        const record = await this.workProfileRepo.findOneBy({id})

        return !!record
    }
}

export function IsExistWorkProfileDbValidate(validationOptions?: ValidationOptions) {
    return function (object: Object, propertyName: string) {
        baseRegisterDecorator({
            name: 'IsExistWorkProfileDbValidate',
            target: object.constructor,
            propertyName: propertyName,
            options: validationOptions,
            validator: IsExistWorkProfileDbValidateConstraint,
        });
    };
}