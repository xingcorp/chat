import {
    ValidationArguments,
    ValidationOptions,
    ValidatorConstraint,
} from "class-validator";
import { baseRegisterDecorator, BaseValidateDecoratorConstraint } from "@decorators/validation/base.validate.decorator";
import { Injectable } from "@nestjs/common";
import { OfficeApprovalRepo } from "@models/repositories";

@ValidatorConstraint({ async: true })
@Injectable()
export class IsCanUpdateApprovalDbValidateConstraint extends BaseValidateDecoratorConstraint {

    constructor(private readonly approvalRepo: OfficeApprovalRepo) {
        super()
        this.messageKey = 'ApprovalCanNotUpdate'
    }

    async checkValidate(id: string, args: ValidationArguments) {
        const data = await this.approvalRepo.getOneCanUpdateBy({id})

        if (data) this.getEntityById(args, data)

        return !!data
    }
}

export function IsCanUpdateApprovalDbValidate(validationOptions?: ValidationOptions) {
    return function (object: Object, propertyName: string) {
        baseRegisterDecorator({
            name: 'IsCanUpdateApprovalDbValidate',
            target: object.constructor,
            propertyName: propertyName,
            options: validationOptions,
            validator: IsCanUpdateApprovalDbValidateConstraint,
        });
    };
}