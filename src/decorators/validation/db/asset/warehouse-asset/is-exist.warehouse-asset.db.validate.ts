import {
    registerDecorator, ValidationArguments,
    ValidationOptions,
    ValidatorConstraint,
} from "class-validator";
import { RequestContext } from "@common/context/request.context";
import { baseRegisterDecorator, BaseValidateDecoratorConstraint } from "@decorators/validation/base.validate.decorator";
import { Injectable } from "@nestjs/common";
import { WarehouseAssetRepo } from "@models/repositories";

@ValidatorConstraint({ async: true })
@Injectable()
export class IsExistWarehouseAssetDbValidateConstraint extends BaseValidateDecoratorConstraint {

    constructor(private readonly warehouseAssetRepo: WarehouseAssetRepo) {
        super()
        this.messageKey = 'WarehouseAssetNotFound'
    }

    async checkValidate(ids: string | string[], args: ValidationArguments) {
        if (!Array.isArray(ids)) ids = [ids]

        const list = await this.warehouseAssetRepo.listByIds(ids)

        return ids.length === list.length
    }
}

export function IsExistWarehouseAssetDbValidate(validationOptions?: ValidationOptions) {
    return function (object: Object, propertyName: string) {
        baseRegisterDecorator({
            name: 'IsExistWarehouseAssetDbValidate',
            target: object.constructor,
            propertyName: propertyName,
            options: validationOptions,
            validator: IsExistWarehouseAssetDbValidateConstraint,
        });
    };
}