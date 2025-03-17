import {
    ValidationArguments,
    ValidationOptions,
    ValidatorConstraint,
} from "class-validator";
import { baseRegisterDecorator, BaseValidateDecoratorConstraint } from "@decorators/validation/base.validate.decorator";
import { Injectable } from "@nestjs/common";
import { OfficeUserRepo } from "@models/repositories";
import { In } from "typeorm";

@ValidatorConstraint({ async: true })
@Injectable()
export class IsExistAndGetUserDbValidateConstraint extends BaseValidateDecoratorConstraint {

    constructor(private officeUserRepo: OfficeUserRepo) {
        super()
        this.messageKey = 'UserNotExist'
    }

    async checkValidate(ids: string | string[], args: ValidationArguments) {
        if (!Array.isArray(ids)) ids = [ids]

        const list = await this.officeUserRepo.getManyBy({id: In(ids)})

        if (list.length) this.getEntityByIdOrIds(args, list)

        return ids.length === list.length
    }
}

export function IsExistAndGetUserDbValidate(validationOptions?: ValidationOptions) {
    return function (object: Object, propertyName: string) {
        baseRegisterDecorator({
            name: 'IsExistAndGetUserDbValidate',
            target: object.constructor,
            propertyName: propertyName,
            options: validationOptions,
            validator: IsExistAndGetUserDbValidateConstraint,
        });
    };
}