import {
    ValidationArguments,
    ValidationOptions,
    ValidatorConstraint,
} from "class-validator";
import { baseRegisterDecorator, BaseValidateDecoratorConstraint } from "@decorators/validation/base.validate.decorator";
import { Injectable } from "@nestjs/common";
import { In, Not } from "typeorm";
import { ProjectLearningRepo } from "@repositories/learning/project.learning.repo";
import { arrayConvertToDistinctAndNotNull } from "@utils/array.utils";

@ValidatorConstraint({ async: true })
@Injectable()
export class IsExistProjectLearningDbValidateConstraint extends BaseValidateDecoratorConstraint {

    constructor(
        private readonly projectLearningRepo: ProjectLearningRepo,
    ) {
        super()
        this.messageKey = 'LearningProjectNotFound'
    }

    async checkValidate(ids: string | string[], args: ValidationArguments) {
        if (!Array.isArray(ids)) ids = [ids]
        ids = arrayConvertToDistinctAndNotNull(ids)
        if (!ids.length) return true

        const where = {
            id: In(ids),
        }

        const list = await this.projectLearningRepo.getManyBy(where, ['skills', 'certificates', 'departments'])

        if (list.length) this.getEntityByIdOrIds(args, list)

        return ids.length === list.length
    }
}

export function IsExistProjectLearningDbValidate(validationOptions?: ValidationOptions) {
    return function (object: Object, propertyName: string) {
        baseRegisterDecorator({
            name: 'IsExistProjectLearningDbValidate',
            target: object.constructor,
            propertyName: propertyName,
            options: validationOptions,
            validator: IsExistProjectLearningDbValidateConstraint,
        });
    };
}