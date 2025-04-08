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
export class IsCodeExistedOrgChartDbValidateConstraint extends BaseValidateDecoratorConstraint {

    constructor(private readonly orgChartRepo: OfficeOrgChartRepo) {
        super()
        this.messageKey = 'OrgChartCodeIsExistNotFound'
    }

    async checkValidate(code: string, args: ValidationArguments) {
        const data = await this.orgChartRepo.getBy({code})

        return !data
    }
}

export function IsCodeExistedOrgChartDbValidate(validationOptions?: ValidationOptions) {
    return function (object: Object, propertyName: string) {
        baseRegisterDecorator({
            name: 'IsCodeExistedOrgChartDbValidate',
            target: object.constructor,
            propertyName: propertyName,
            options: validationOptions,
            validator: IsCodeExistedOrgChartDbValidateConstraint,
        });
    };
}