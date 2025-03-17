import { baseRegisterDecorator, BaseValidateDecoratorConstraint } from "@decorators/validation/base.validate.decorator";
import { AddressLearningRepo } from "@models/repositories/learning/address.learning.repo";
import { Injectable } from "@nestjs/common";
import { arrayConvertToDistinctAndNotNull } from "@utils/array.utils";
import { ValidationArguments, ValidationOptions, ValidatorConstraint } from "class-validator";
import { In } from "typeorm";

@ValidatorConstraint({async:true})
@Injectable()
export class IsExistAddressLearningDbValidateConstraint extends BaseValidateDecoratorConstraint {
    constructor(
        private readonly addressLearningRepo: AddressLearningRepo
    ) {
        super()
        this.messageKey = 'LearningAddressNotFound'
    }

    async checkValidate(ids: string | string[], args: ValidationArguments) {
        if (!Array.isArray(ids)) ids = [ids]
        ids = arrayConvertToDistinctAndNotNull(ids)
        if (!ids.length) return true

        const where = {
            id: In(ids),
        }

        const list = await this.addressLearningRepo.getManyBy(where)

        if (list.length) this.getEntityByIdOrIds(args, list)

        return ids.length === list.length
    }
}

export function IsExistAddressLearningDbValidate(validationOptions?: ValidationOptions) {
    return function (object: Object, propertyName: string) {
        baseRegisterDecorator({
            name: 'IsExistAddressLearningDbValidate',
            target: object.constructor,
            propertyName: propertyName,
            options: validationOptions,
            validator: IsExistAddressLearningDbValidateConstraint,
        });
    };
}