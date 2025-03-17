import {
    ValidationArguments,
    ValidationOptions,
    ValidatorConstraint,
} from "class-validator";
import { baseRegisterDecorator, BaseValidateDecoratorConstraint } from "@decorators/validation/base.validate.decorator";
import { Injectable } from "@nestjs/common";
import { CategoryWikiRepo } from "@models/repositories";
import { In } from "typeorm";
import { arrayConvertToDistinctAndNotNull } from "@utils/array.utils";

@ValidatorConstraint({ async: true })
@Injectable()
export class IsExistCategoryWikiDbValidateConstraint extends BaseValidateDecoratorConstraint {

    constructor(private readonly categoryWikiRepo: CategoryWikiRepo) {
        super()
        this.messageKey = 'CategoryWikiNotFound'
    }

    async checkValidate(ids: string | string[], args: ValidationArguments) {
        if (!Array.isArray(ids)) ids = [ids]
        ids = arrayConvertToDistinctAndNotNull(ids)
        if (!ids.length) return true

        const where = {
            id: In(ids),
        }

        const list = await this.categoryWikiRepo.getBy(where)

        if (list.length) this.getEntityByIdOrIds(args, list)

        return ids.length === list.length
    }
}

export function IsExistCategoryWikiDbValidate(validationOptions?: ValidationOptions) {
    return function (object: Object, propertyName: string) {
        baseRegisterDecorator({
            name: 'IsExistCategoryWikiDbValidate',
            target: object.constructor,
            propertyName: propertyName,
            options: validationOptions,
            validator: IsExistCategoryWikiDbValidateConstraint,
        });
    };
}