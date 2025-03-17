import {
    ValidationArguments,
    ValidationOptions,
    ValidatorConstraint,
} from "class-validator";
import { baseRegisterDecorator, BaseValidateDecoratorConstraint } from "@decorators/validation/base.validate.decorator";
import { Injectable } from "@nestjs/common";
import { Not } from "typeorm";
import { SectionLearningRepo } from "@models/repositories";

@ValidatorConstraint({ async: true })
@Injectable()
export class IsNameNotExistSectionLearningDbValidateConstraint extends BaseValidateDecoratorConstraint {

    constructor(
        private readonly sectionLearningRepo: SectionLearningRepo,
    ) {
        super()
        this.messageKey = 'LearningCourseNameExisted'
    }

    async checkValidate(name: string, args: ValidationArguments) {
        let _thisId = args.object['IsNameNotExistSectionLearningDbValidate_sectionId']

        const where = { name }

        if (_thisId) {
            where['id'] = Not(_thisId)
        }

        return !(await this.sectionLearningRepo.count({ where }))
    }
}

export function IsNameNotExistSectionLearningDbValidate(validationOptions?: ValidationOptions) {
    return function (object: Object, propertyName: string) {
        baseRegisterDecorator({
            name: 'IsNameNotExistSectionLearningDbValidate',
            target: object.constructor,
            propertyName: propertyName,
            options: validationOptions,
            validator: IsNameNotExistSectionLearningDbValidateConstraint,
        });
    };
}