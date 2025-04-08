import {
    ValidationArguments,
    ValidationOptions,
    ValidatorConstraint,
} from "class-validator";
import { Injectable } from "@nestjs/common";
import { AssetRepo } from "@models/repositories";
import { baseRegisterDecorator, BaseValidateDecoratorConstraint } from "@decorators/validation/base.validate.decorator";

@ValidatorConstraint({async: true})
@Injectable()
export class IsExistCodeAssetDbValidateConstraint extends BaseValidateDecoratorConstraint {

    constructor(
        private readonly assetRepo: AssetRepo
    ) {
        super()
        this.messageKey = 'AssetNotFound'
    }

    async checkValidate(code: string, args: ValidationArguments) {
        const data = await this.assetRepo.getBy({code})

        if (data) this.getEntityByCode(args, data)

        return !!data
    }
}

export function IsExistCodeAssetDbValidate(validationOptions?: ValidationOptions) {
    return function (object: Object, propertyName: string) {
        baseRegisterDecorator({
            name: 'IsExistCodeAssetDbValidate',
            target: object.constructor,
            propertyName: propertyName,
            options: validationOptions,
            validator: IsExistCodeAssetDbValidateConstraint,
        });
    };
}