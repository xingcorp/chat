import {
    registerDecorator, ValidationArguments,
    ValidationOptions,
    ValidatorConstraint,
} from "class-validator";
import { RequestContext } from "@common/context/request.context";
import { baseRegisterDecorator, BaseValidateDecoratorConstraint } from "@decorators/validation/base.validate.decorator";
import { Injectable } from "@nestjs/common";
import { ApprovalFormGroupRepo, CategoryAssetRepo } from "@models/repositories";
import { In } from "typeorm";

@ValidatorConstraint({ async: true })
@Injectable()
export class IsExistApprovalFormGroupDbValidateConstraint extends BaseValidateDecoratorConstraint {

    constructor(private readonly formGroupRepo: ApprovalFormGroupRepo) {
        super()
        this.messageKey = 'ApprovalFormGroupNotExist'
    }

    async checkValidate(ids: string | string[], args: ValidationArguments) {
        if (!Array.isArray(ids)) ids = [ids]
        const where = {
            id: In(ids),
        }

        const list = await this.formGroupRepo.getBy(where)

        if (list.length) this.getEntityByIdOrIds(args, list)

        return ids.length === list.length
    }
}

export function IsExistApprovalFormGroupDbValidate(validationOptions?: ValidationOptions) {
    return function (object: Object, propertyName: string) {
        baseRegisterDecorator({
            name: 'IsExistApprovalFormGroupDbValidate',
            target: object.constructor,
            propertyName: propertyName,
            options: validationOptions,
            validator: IsExistApprovalFormGroupDbValidateConstraint,
        });
    };
}