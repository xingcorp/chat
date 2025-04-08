import {
    registerDecorator, ValidationArguments,
    ValidationOptions,
    ValidatorConstraint,
} from "class-validator";
import { RequestContext } from "@common/context/request.context";
import { baseRegisterDecorator, BaseValidateDecoratorConstraint } from "@decorators/validation/base.validate.decorator";
import { Injectable } from "@nestjs/common";
import { FilterRepo } from "@repositories/index";
import { Not } from "typeorm";

@ValidatorConstraint({ async: true })
@Injectable()
export class IsNameNotExistTaskFilterDbValidateConstraint extends BaseValidateDecoratorConstraint {

    constructor(private readonly filterRepo: FilterRepo) {
        super()
        this.messageKey = 'FilterNameExist'
    }

    async checkValidate(name: string, args: ValidationArguments) {
        const where = {
            name,
            relationId: await RequestContext.currentId()
        }
        const filterId = args.object['IsNameNotExistTaskFilterDbValidate_filterId']

        if (filterId) where['id'] = Not(filterId)

        const data = await this.filterRepo.taskGetOneBy(where)

        return !data
    }
}

export function IsNameNotExistTaskFilterDbValidate(validationOptions?: ValidationOptions) {
    return function (object: Object, propertyName: string) {
        baseRegisterDecorator({
            name: 'IsNameNotExistTaskFilterDbValidate',
            target: object.constructor,
            propertyName: propertyName,
            options: validationOptions,
            validator: IsNameNotExistTaskFilterDbValidateConstraint,
        });
    };
}