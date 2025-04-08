import {
    ValidationArguments,
    ValidationOptions,
    ValidatorConstraint,
} from "class-validator";
import { Injectable } from "@nestjs/common";
import { CategoryAssetRepo, OfficeUserRepo } from "@models/repositories";
import { baseRegisterDecorator, BaseValidateDecoratorConstraint } from "@decorators/validation/base.validate.decorator";
import { BaseEntity, DataSource } from "typeorm";

@ValidatorConstraint({async: true})
@Injectable()
export class IsExistCodeCategoryAssetDbValidateConstraint extends BaseValidateDecoratorConstraint {

    constructor(
        private readonly categoryAssetRepo: CategoryAssetRepo
    ) {
        super()
        this.messageKey = 'CategoryAssetNotFound'
    }

    async checkValidate(code: string, args: ValidationArguments) {
        const data = await this.categoryAssetRepo.getBy({code})

        if (data) this.getEntityByCode(args, data)

        return !!data
    }
}

export function IsExistCodeCategoryAssetDbValidate(validationOptions?: ValidationOptions) {
    return function (object: Object, propertyName: string) {
        baseRegisterDecorator({
            name: 'IsExistCodeCategoryAssetDbValidate',
            target: object.constructor,
            propertyName: propertyName,
            options: validationOptions,
            validator: IsExistCodeCategoryAssetDbValidateConstraint,
        });
    };
}