import {
    registerDecorator, ValidationArguments,
    ValidationOptions,
    ValidatorConstraint,
} from "class-validator";
import { RequestContext } from "@common/context/request.context";
import { baseRegisterDecorator, BaseValidateDecoratorConstraint } from "@decorators/validation/base.validate.decorator";
import { Injectable } from "@nestjs/common";
import { ApprovalFormGroupRepo, CategoryAssetRepo, OfficeApprovalRepo } from "@models/repositories";
import { In } from "typeorm";

@ValidatorConstraint({ async: true })
@Injectable()
export class IsExistApprovalDbValidateConstraint extends BaseValidateDecoratorConstraint {

    constructor(private readonly approvalRepo: OfficeApprovalRepo) {
        super()
        this.messageKey = 'ApprovalNotFound'
    }

    async checkValidate(ids: string | string[], args: ValidationArguments) {
        if (!Array.isArray(ids)) ids = [ids]
        const where = {
            id: In(ids),
        }

        const list = await this.approvalRepo.getManyBy(where)

        if (list.length) this.getEntityByIdOrIds(args, list)

        return ids.length === list.length
    }
}

export function IsExistApprovalDbValidate(validationOptions?: ValidationOptions) {
    return function (object: Object, propertyName: string) {
        baseRegisterDecorator({
            name: 'IsExistApprovalDbValidate',
            target: object.constructor,
            propertyName: propertyName,
            options: validationOptions,
            validator: IsExistApprovalDbValidateConstraint,
        });
    };
}