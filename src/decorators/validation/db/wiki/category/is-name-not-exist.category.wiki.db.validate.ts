import {
    ValidationArguments,
    ValidationOptions,
    ValidatorConstraint,
} from "class-validator";
import { baseRegisterDecorator, BaseValidateDecoratorConstraint } from "@decorators/validation/base.validate.decorator";
import { Injectable } from "@nestjs/common";
import { CategoryWikiRepo } from "@repositories/index";
import { Not } from "typeorm";

@ValidatorConstraint({ async: true })
@Injectable()
export class IsNameNotExistCategoryWikiDbValidateConstraint extends BaseValidateDecoratorConstraint {

    constructor(private readonly categoryWikiRepo: CategoryWikiRepo) {
        super()
        this.messageKey = 'CategoryWikiNameExist'
    }

    async checkValidate(name: string, args: ValidationArguments) {
        const where = {
            name,
        }
        const exceptId = args.object['IsNameNotExistCategoryWikiDbValidate_exceptId']

        if (exceptId) where['id'] = Not(exceptId)

        const data = await this.categoryWikiRepo.getOneBy(where)

        return !data
    }
}

export function IsNameNotExistCategoryWikiDbValidate(validationOptions?: ValidationOptions) {
    return function (object: Object, propertyName: string) {
        baseRegisterDecorator({
            name: 'IsNameNotExistCategoryWikiDbValidate',
            target: object.constructor,
            propertyName: propertyName,
            options: validationOptions,
            validator: IsNameNotExistCategoryWikiDbValidateConstraint,
        });
    };
}