import {
    ValidationArguments,
    ValidationOptions,
    ValidatorConstraint,
} from "class-validator";
import { baseRegisterDecorator, BaseValidateDecoratorConstraint } from "@decorators/validation/base.validate.decorator";
import { Injectable } from "@nestjs/common";
import { WikiRepo } from "@repositories/index";

@ValidatorConstraint({ async: true })
@Injectable()
export class IsExistWikiDbValidateConstraint extends BaseValidateDecoratorConstraint {

    constructor(private readonly wikiRepo: WikiRepo) {
        super()
        this.messageKey = 'DocumentWikiNotFound'
    }

    async checkValidate(id: string, args: ValidationArguments) {
        const data = await this.wikiRepo.createQueryBuilder('qb')
            .leftJoinAndSelect('qb.folder', 'folder')
            .leftJoinAndSelect('qb.orgCharts', 'orgCharts')
            .where({id})
            .getOne()

        if (data) this.getEntityById(args, data)

        return !!data
    }
}

export function IsExistWikiDbValidate(validationOptions?: ValidationOptions) {
    return function (object: Object, propertyName: string) {
        baseRegisterDecorator({
            name: 'IsExistWikiDbValidate',
            target: object.constructor,
            propertyName: propertyName,
            options: validationOptions,
            validator: IsExistWikiDbValidateConstraint,
        });
    };
}