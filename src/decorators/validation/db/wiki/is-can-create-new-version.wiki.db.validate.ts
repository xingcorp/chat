import {
    ValidationArguments,
    ValidationOptions,
    ValidatorConstraint,
} from "class-validator";
import { baseRegisterDecorator, BaseValidateDecoratorConstraint } from "@decorators/validation/base.validate.decorator";
import { Injectable } from "@nestjs/common";
import { VersionWikiRepo, WikiRepo } from "@models/repositories";
import { VersionWikiStatus } from "@enum/wiki/wiki.enum";

@ValidatorConstraint({ async: true })
@Injectable()
export class IsCanCreateNewVersionWikiDbValidateConstraint extends BaseValidateDecoratorConstraint {

    constructor(
        private readonly versionWikiRepo: VersionWikiRepo,
    ) {
        super()
        this.messageKey = 'DocumentWikiCanNotCreateNewVer'
    }

    async checkValidate(id: string, args: ValidationArguments) {

        if (args.object['status'] === VersionWikiStatus.Draft) return true

        const data = await this.versionWikiRepo.waitingApprovalGetByWikiId(id)

        return !data
    }
}

export function IsCanCreateNewVersionWikiDbValidate(validationOptions?: ValidationOptions) {
    return function (object: Object, propertyName: string) {
        baseRegisterDecorator({
            name: 'IsCanCreateNewVersionWikiDbValidate',
            target: object.constructor,
            propertyName: propertyName,
            options: validationOptions,
            validator: IsCanCreateNewVersionWikiDbValidateConstraint,
        });
    };
}