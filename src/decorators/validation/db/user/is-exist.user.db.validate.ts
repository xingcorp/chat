import {
    ValidationArguments,
    ValidationOptions,
    ValidatorConstraint,
} from "class-validator";
import { RequestContext } from "@common/context/request.context";
import { baseRegisterDecorator, BaseValidateDecoratorConstraint } from "@decorators/validation/base.validate.decorator";
import { Injectable } from "@nestjs/common";

@ValidatorConstraint({ async: true })
@Injectable()
export class IsExistUserDbValidateConstraint extends BaseValidateDecoratorConstraint {

    constructor() {
        super()
        this.messageKey = 'UserNotExist'
    }

    async checkValidate(ids: string | string[], args: ValidationArguments) {
        const userIds = await RequestContext.currentOrgDataUserIds()
        if (!Array.isArray(ids)) ids = [ids]

        return !(ids.some(id => !userIds.includes(id)))
    }
}

export function IsExistUserDbValidate(validationOptions?: ValidationOptions) {
    return function (object: Object, propertyName: string) {
        baseRegisterDecorator({
            name: 'IsExistUserDbValidate',
            target: object.constructor,
            propertyName: propertyName,
            options: validationOptions,
            validator: IsExistUserDbValidateConstraint,
        });
    };
}