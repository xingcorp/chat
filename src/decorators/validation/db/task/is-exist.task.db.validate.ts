import {
    ValidationArguments,
    ValidationOptions,
    ValidatorConstraint,
} from "class-validator";
import { baseRegisterDecorator, BaseValidateDecoratorConstraint } from "@decorators/validation/base.validate.decorator";
import { Injectable } from "@nestjs/common";
import { OfficeTaskRepo } from "@models/repositories";
import { arrayConvertToDistinctAndNotNull } from "@utils/array.utils";
import { In } from "typeorm";

@ValidatorConstraint({ async: true })
@Injectable()
export class IsExistTaskDbValidateConstraint extends BaseValidateDecoratorConstraint {

    constructor(private readonly officeTaskRepo: OfficeTaskRepo) {
        super()
        this.messageKey = 'TaskNotExist'
    }

    async checkValidate(ids: string | string[], args: ValidationArguments) {
        if (!Array.isArray(ids)) ids = [ids]
        ids = arrayConvertToDistinctAndNotNull(ids)
        if (!ids.length) return true

        const where = {
            id: In(ids),
        }

        const list = await this.officeTaskRepo.getManyBy(where)

        if (list.length) this.getEntityByIdOrIds(args, list)

        return ids.length === list.length
    }
}

export function IsExistTaskDbValidate(validationOptions?: ValidationOptions) {
    return function (object: Object, propertyName: string) {
        baseRegisterDecorator({
            name: 'IsExistTaskDbValidate',
            target: object.constructor,
            propertyName: propertyName,
            options: validationOptions,
            validator: IsExistTaskDbValidateConstraint,
        });
    };
}