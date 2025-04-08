import {
    registerDecorator, ValidationArguments,
    ValidationOptions,
    ValidatorConstraint,
} from "class-validator";
import { RequestContext } from "@common/context/request.context";
import { baseRegisterDecorator, BaseValidateDecoratorConstraint } from "@decorators/validation/base.validate.decorator";
import { Injectable } from "@nestjs/common";
import { ApprovalFormGroupRepo, FilterRepo } from "@repositories/index";
import { In, Not } from "typeorm";

@ValidatorConstraint({ async: true })
@Injectable()
export class IsNameNotExistApprovalFormGroupDbValidateConstraint extends BaseValidateDecoratorConstraint {

    constructor(private readonly formGroupRepo: ApprovalFormGroupRepo) {
        super()
        this.messageKey = 'ApprovalFormGroupNameExist'
    }

    async checkValidate(name: string, args: ValidationArguments) {
        const where = {
            name,
        }
        const formGroupId = args.object['IsNameNotExistApprovalFormGroupDbValidate_formGroupId']

        if (formGroupId) where['id'] = Not(formGroupId)

        const data = await this.formGroupRepo.getOneBy(where)

        return !data
    }
}

export function IsNameNotExistApprovalFormGroupDbValidate(validationOptions?: ValidationOptions) {
    return function (object: Object, propertyName: string) {
        baseRegisterDecorator({
            name: 'IsNameNotExistApprovalFormGroupDbValidate',
            target: object.constructor,
            propertyName: propertyName,
            options: validationOptions,
            validator: IsNameNotExistApprovalFormGroupDbValidateConstraint,
        });
    };
}