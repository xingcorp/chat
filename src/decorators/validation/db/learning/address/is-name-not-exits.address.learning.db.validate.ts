import { baseRegisterDecorator, BaseValidateDecoratorConstraint } from "@decorators/validation/base.validate.decorator";
import { AddressLearningRepo } from "@models/repositories/learning/address.learning.repo";
import { Injectable } from "@nestjs/common";
import { ValidationArguments, ValidationOptions, ValidatorConstraint } from "class-validator";
import { Not } from "typeorm";

@ValidatorConstraint({ async: true })
@Injectable()
export class IsNameNotExistAddressLearningDbValidateConstraint extends BaseValidateDecoratorConstraint {
    constructor(
        private readonly addressLearningRepo: AddressLearningRepo,
    ) {
        super()
        this.messageKey = 'LearningAddressNameExisted'
    }

    async checkValidate(name: string, args: ValidationArguments) {
        let _thisId = args.object['addressId']

        const where = { name }

        if (_thisId) {
            where['id'] = Not(_thisId)
        }

        return !(await this.addressLearningRepo.count({ where }))
    }
}

export function IsNameNotExistAddressLearningDbValidate(validationOptions?: ValidationOptions) {
    return function (object: Object, propertyName: string) {
        baseRegisterDecorator({
            name: 'IsNameNotExistAddressLearningDbValidate',
            target: object.constructor,
            propertyName: propertyName,
            options: validationOptions,
            validator: IsNameNotExistAddressLearningDbValidateConstraint,
        });
    };
}