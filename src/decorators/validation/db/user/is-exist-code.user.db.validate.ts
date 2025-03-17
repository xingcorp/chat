import {
    ValidationArguments,
    ValidationOptions,
    ValidatorConstraint,
} from "class-validator";
import { Injectable } from "@nestjs/common";
import { OfficeUserRepo } from "@models/repositories";
import { baseRegisterDecorator, BaseValidateDecoratorConstraint } from "@decorators/validation/base.validate.decorator";
import { DataSource } from "typeorm";

@ValidatorConstraint({async: true})
@Injectable()
export class IsExistCodeUserDbValidateConstraint extends BaseValidateDecoratorConstraint {

    constructor(
        private dataSource: DataSource,
        private officeUserRepo: OfficeUserRepo
    ) {
        super()
        this.messageKey = 'EmployeeCodeIsNotExisted'
    }

    async checkValidate(code: string, args: ValidationArguments) {
        const data = await this.officeUserRepo.getBy({code})

        if (data) this.getEntityByCode(args, data)

        return !!data
    }
}

export function IsExistCodeUserDbValidate(validationOptions?: ValidationOptions) {
    return function (object: Object, propertyName: string) {
        baseRegisterDecorator({
            name: 'IsExistCodeUserDbValidate',
            target: object.constructor,
            propertyName: propertyName,
            options: validationOptions,
            validator: IsExistCodeUserDbValidateConstraint,
        });
    };
}