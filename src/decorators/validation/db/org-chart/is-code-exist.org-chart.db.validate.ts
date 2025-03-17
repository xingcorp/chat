import {
    registerDecorator, ValidationArguments,
    ValidationOptions,
    ValidatorConstraint,
} from "class-validator";
import { RequestContext } from "@common/context/request.context";
import { baseRegisterDecorator, BaseValidateDecoratorConstraint } from "@decorators/validation/base.validate.decorator";
import { Injectable } from "@nestjs/common";
import { OfficeOrgChartRepo } from "@models/repositories";

@ValidatorConstraint({ async: true })
@Injectable()
export class IsCodeExistOrgChartDbValidateConstraint extends BaseValidateDecoratorConstraint {

    constructor(private readonly orgChartRepo: OfficeOrgChartRepo) {
        super()
        this.messageKey = 'OrgChartNotFound'
    }

    async checkValidate(code: string, args: ValidationArguments) {
        const data = await this.orgChartRepo.getBy({code})

        if (data) this.getEntityByCode(args, data)

        return !!data
    }
}

export function IsCodeExistOrgChartDbValidate(validationOptions?: ValidationOptions) {
    return function (object: Object, propertyName: string) {
        baseRegisterDecorator({
            name: 'IsCodeExistOrgChartDbValidate',
            target: object.constructor,
            propertyName: propertyName,
            options: validationOptions,
            validator: IsCodeExistOrgChartDbValidateConstraint,
        });
    };
}