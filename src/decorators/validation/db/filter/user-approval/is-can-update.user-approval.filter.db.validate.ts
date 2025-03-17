import {
    registerDecorator, ValidationArguments,
    ValidationOptions,
    ValidatorConstraint,
} from "class-validator";
import { RequestContext } from "@common/context/request.context";
import { baseRegisterDecorator, BaseValidateDecoratorConstraint } from "@decorators/validation/base.validate.decorator";
import { Injectable } from "@nestjs/common";
import { FilterRepo } from "@models/repositories";
import { Not } from "typeorm";

@ValidatorConstraint({ async: true })
@Injectable()
export class IsCanUpdateUserApprovalFilterDbValidateConstraint extends BaseValidateDecoratorConstraint {

    constructor(private readonly filterRepo: FilterRepo) {
        super()
        this.messageKey = 'FilterUserApprovalNameExist'
    }

    async checkValidate(id: string, args: ValidationArguments) {
        const where = {
            id,
            relationId: await RequestContext.currentId()
        }

        const data = await this.filterRepo.userApprovalGetOneBy(where)

        if (data) this.getEntityById(args, data)

        return !!data
    }
}

export function IsCanUpdateUserApprovalFilterDbValidate(validationOptions?: ValidationOptions) {
    return function (object: Object, propertyName: string) {
        baseRegisterDecorator({
            name: 'IsCanUpdateUserApprovalFilterDbValidate',
            target: object.constructor,
            propertyName: propertyName,
            options: validationOptions,
            validator: IsCanUpdateUserApprovalFilterDbValidateConstraint,
        });
    };
}