import {
    ValidationArguments,
    ValidationOptions,
    ValidatorConstraint,
} from "class-validator";
import { Injectable } from "@nestjs/common";
import { CategoryAssetRepo, OfficeUserRepo, WarehouseAssetRepo } from "@models/repositories";
import { baseRegisterDecorator, BaseValidateDecoratorConstraint } from "@decorators/validation/base.validate.decorator";
import { DataSource } from "typeorm";

@ValidatorConstraint({async: true})
@Injectable()
export class IsExistCodeWarehouseAssetDbValidateConstraint extends BaseValidateDecoratorConstraint {

    constructor(
        private readonly warehouseAssetRepo: WarehouseAssetRepo
    ) {
        super()
        this.messageKey = 'WarehouseAssetNotFound'
    }

    async checkValidate(code: string, args: ValidationArguments) {
        const data = await this.warehouseAssetRepo.getBy({code})

        if (data) this.getEntityByCode(args, data)

        return !!data
    }
}

export function IsExistCodeWarehouseAssetDbValidate(validationOptions?: ValidationOptions) {
    return function (object: Object, propertyName: string) {
        baseRegisterDecorator({
            name: 'IsExistCodeWarehouseAssetDbValidate',
            target: object.constructor,
            propertyName: propertyName,
            options: validationOptions,
            validator: IsExistCodeWarehouseAssetDbValidateConstraint,
        });
    };
}