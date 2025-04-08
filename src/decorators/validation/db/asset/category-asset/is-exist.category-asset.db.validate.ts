import {
    registerDecorator, ValidationArguments,
    ValidationOptions,
    ValidatorConstraint,
} from "class-validator";
import { RequestContext } from "@common/context/request.context";
import { baseRegisterDecorator, BaseValidateDecoratorConstraint } from "@decorators/validation/base.validate.decorator";
import { Injectable } from "@nestjs/common";
import { CategoryAssetRepo } from "@models/repositories";

@ValidatorConstraint({ async: true })
@Injectable()
export class IsExistCategoryAssetDbValidateConstraint extends BaseValidateDecoratorConstraint {

    constructor(private readonly categoryAssetRepo: CategoryAssetRepo) {
        super()
        this.messageKey = 'CategoryAssetNotFound'
    }

    async checkValidate(ids: string | string[], args: ValidationArguments) {
        if (!Array.isArray(ids)) ids = [ids]

        const list = await this.categoryAssetRepo.listByIds(ids)

        return ids.length === list.length
    }
}

export function IsExistCategoryAssetDbValidate(validationOptions?: ValidationOptions) {
    return function (object: Object, propertyName: string) {
        baseRegisterDecorator({
            name: 'IsExistCategoryAssetDbValidate',
            target: object.constructor,
            propertyName: propertyName,
            options: validationOptions,
            validator: IsExistCategoryAssetDbValidateConstraint,
        });
    };
}