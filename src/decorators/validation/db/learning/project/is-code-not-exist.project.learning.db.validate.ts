import {
    ValidationArguments,
    ValidationOptions,
    ValidatorConstraint,
} from "class-validator";
import { baseRegisterDecorator, BaseValidateDecoratorConstraint } from "@decorators/validation/base.validate.decorator";
import { Injectable } from "@nestjs/common";
import { Not } from "typeorm";
import { ProjectLearningRepo } from "@repositories/learning/project.learning.repo";

@ValidatorConstraint({ async: true })
@Injectable()
export class IsCodeNotExistProjectLearningDbValidateConstraint extends BaseValidateDecoratorConstraint {

    constructor(
        private readonly projectLearningRepo: ProjectLearningRepo,
    ) {
        super()
        this.messageKey = 'LearningProjectCodeExisted'
    }

    async checkValidate(code: string, args: ValidationArguments) {
        let projectId = args.object['projectId']

        const where = {code}

        if (projectId) {
            where['id'] = Not(projectId)
        }

        return !(await this.projectLearningRepo.count({where}))
    }
}

export function IsCodeNotExistProjectLearningDbValidate(validationOptions?: ValidationOptions) {
    return function (object: Object, propertyName: string) {
        baseRegisterDecorator({
            name: 'IsCodeNotExistProjectLearningDbValidate',
            target: object.constructor,
            propertyName: propertyName,
            options: validationOptions,
            validator: IsCodeNotExistProjectLearningDbValidateConstraint,
        });
    };
}