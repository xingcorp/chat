import {
    ValidationArguments,
    ValidationOptions,
    ValidatorConstraint,
} from "class-validator";
import { baseRegisterDecorator, BaseValidateDecoratorConstraint } from "@decorators/validation/base.validate.decorator";
import { Injectable } from "@nestjs/common";
import { TagDocumentRepo } from "@repositories/index";
import { Not } from "typeorm";

@ValidatorConstraint({ async: true })
@Injectable()
export class IsNameNotExistTagDocumentDbValidateConstraint extends BaseValidateDecoratorConstraint {

    constructor(private readonly tagDocumentRepo: TagDocumentRepo) {
        super()
        this.messageKey = 'TagDocumentNameExist'
    }

    async checkValidate(name: string, args: ValidationArguments) {
        const where = {
            name,
        }
        const exceptId = args.object['IsNameNotExistTagDocumentDbValidate_exceptId']

        if (exceptId) where['id'] = Not(exceptId)

        const data = await this.tagDocumentRepo.getOneBy(where)

        return !data
    }
}

export function IsNameNotExistTagDocumentDbValidate(validationOptions?: ValidationOptions) {
    return function (object: Object, propertyName: string) {
        baseRegisterDecorator({
            name: 'IsNameNotExistTagDocumentDbValidate',
            target: object.constructor,
            propertyName: propertyName,
            options: validationOptions,
            validator: IsNameNotExistTagDocumentDbValidateConstraint,
        });
    };
}