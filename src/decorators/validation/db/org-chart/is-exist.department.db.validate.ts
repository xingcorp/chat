import {
    ValidationArguments,
    ValidationOptions,
    ValidatorConstraint,
} from "class-validator";
import { baseRegisterDecorator, BaseValidateDecoratorConstraint } from "@decorators/validation/base.validate.decorator";
import { Injectable } from "@nestjs/common";
import { arrayConvertToDistinctAndNotNull } from "@utils/array.utils";
import { In } from "typeorm";
import { OfficeOrgChartRepo } from "@models/repositories";

@ValidatorConstraint({ async: true })
@Injectable()
export class IsExistDepartmentDbValidateConstraint extends BaseValidateDecoratorConstraint {

    constructor(
        private readonly orgChartRepo: OfficeOrgChartRepo,
    ) {
        super()
        this.messageKey = 'OrgChartNotFound'
    }

    async checkValidate(ids: string | string[], args: ValidationArguments) {
        if (!Array.isArray(ids)) ids = [ids]
        ids = arrayConvertToDistinctAndNotNull(ids)
        if (!ids.length) return true

        const where = {
            id: In(ids),
        }

        const list = await this.orgChartRepo.getManyBy(where)

        if (list.length) this.getEntityByIdOrIds(args, list)

        return ids.length === list.length
    }
}

export function IsExistDepartmentDbValidate(validationOptions?: ValidationOptions) {
    return function (object: Object, propertyName: string) {
        baseRegisterDecorator({
            name: 'IsExistDepartmentDbValidate',
            target: object.constructor,
            propertyName: propertyName,
            options: validationOptions,
            validator: IsExistDepartmentDbValidateConstraint,
        });
    };
}