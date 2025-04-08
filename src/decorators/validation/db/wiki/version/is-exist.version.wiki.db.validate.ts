import {
    ValidationArguments,
    ValidationOptions,
    ValidatorConstraint,
} from "class-validator";
import { baseRegisterDecorator, BaseValidateDecoratorConstraint } from "@decorators/validation/base.validate.decorator";
import { Injectable } from "@nestjs/common";
import { VersionWikiRepo, WikiRepo } from "@repositories/index";

@ValidatorConstraint({ async: true })
@Injectable()
export class IsExistVersionWikiDbValidateConstraint extends BaseValidateDecoratorConstraint {

    constructor(private readonly versionWikiRepo: VersionWikiRepo) {
        super()
        this.messageKey = 'VersionWikiNotFound'
    }

    async checkValidate(id: string, args: ValidationArguments) {
        const data = await this.versionWikiRepo.createQueryBuilder('qb')
            .leftJoinAndSelect('qb.wiki', 'wiki')
            .leftJoinAndSelect('qb.tags', 'tags')
            .where({id})
            .getOne()

        if (data) this.getEntityById(args, data)

        return !!data
    }
}

export function IsExistVersionWikiDbValidate(validationOptions?: ValidationOptions) {
    return function (object: Object, propertyName: string) {
        baseRegisterDecorator({
            name: 'IsExistVersionWikiDbValidate',
            target: object.constructor,
            propertyName: propertyName,
            options: validationOptions,
            validator: IsExistVersionWikiDbValidateConstraint,
        });
    };
}