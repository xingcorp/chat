import {
    ValidationArguments,
    ValidationOptions,
    ValidatorConstraint,
} from "class-validator";
import { baseRegisterDecorator, BaseValidateDecoratorConstraint } from "@decorators/validation/base.validate.decorator";
import { Injectable } from "@nestjs/common";
import { Not } from "typeorm";
import { CertificateLearningRepo } from "@models/repositories";

@ValidatorConstraint({ async: true })
@Injectable()
export class IsNameNotExistCertificateLearningDbValidateConstraint extends BaseValidateDecoratorConstraint {

    constructor(
        private readonly certificateLearningRepo: CertificateLearningRepo,
    ) {
        super()
        this.messageKey = 'LearningCertificateNameExisted'
    }

    async checkValidate(name: string, args: ValidationArguments) {
        let _thisId = args.object['IsNameNotExistCertificateLearningDbValidate_certificateId']

        const where = {name}

        if (_thisId) {
            where['id'] = Not(_thisId)
        }

        return !(await this.certificateLearningRepo.count({where}))
    }
}

export function IsNameNotExistCertificateLearningDbValidate(validationOptions?: ValidationOptions) {
    return function (object: Object, propertyName: string) {
        baseRegisterDecorator({
            name: 'IsNameNotExistCertificateLearningDbValidate',
            target: object.constructor,
            propertyName: propertyName,
            options: validationOptions,
            validator: IsNameNotExistCertificateLearningDbValidateConstraint,
        });
    };
}