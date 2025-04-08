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
export class IsNameNotExistUserApprovalFilterDbValidateConstraint extends BaseValidateDecoratorConstraint {

    constructor(private readonly filterRepo: FilterRepo) {
        super()
        this.messageKey = 'FilterUserApprovalNameExist'
    }

    async checkValidate(name: string, args: ValidationArguments) {
        const where = {
            name,
            relationId: await RequestContext.currentId()
        }
        const filterId = args.object['IsNameNotExistUserApprovalFilterDbValidate_filterId']

        if (filterId) where['id'] = Not(filterId)

        const data = await this.filterRepo.userApprovalGetOneBy(where)

        return !data
    }
}

export function IsNameNotExistUserApprovalFilterDbValidate(validationOptions?: ValidationOptions) {
    return function (object: Object, propertyName: string) {
        baseRegisterDecorator({
            name: 'IsNameNotExistUserApprovalFilterDbValidate',
            target: object.constructor,
            propertyName: propertyName,
            options: validationOptions,
            validator: IsNameNotExistUserApprovalFilterDbValidateConstraint,
        });
    };
}