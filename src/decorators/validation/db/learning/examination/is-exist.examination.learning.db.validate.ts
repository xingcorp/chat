import {
    ValidationArguments,
    ValidationOptions,
    ValidatorConstraint,
} from "class-validator";
import { baseRegisterDecorator, BaseValidateDecoratorConstraint } from "@decorators/validation/base.validate.decorator";
import { Injectable } from "@nestjs/common";
import { In } from "typeorm";
import { arrayConvertToDistinctAndNotNull } from "@utils/array.utils";
import { ExaminationLearningRepo } from "@models/repositories/learning/examination.learning.repo";

@ValidatorConstraint({ async: true })
@Injectable()
export class IsExistExaminationLearningDbValidateConstraint extends BaseValidateDecoratorConstraint {

    constructor(
        private readonly examinationLearningRepo: ExaminationLearningRepo,
    ) {
        super()
        this.messageKey = 'LearningExaminationNotFound'
    }

    async checkValidate(ids: string | string[], args: ValidationArguments) {
        if (!Array.isArray(ids)) ids = [ids]
        ids = arrayConvertToDistinctAndNotNull(ids)
        if (!ids.length) return true

        const where = {
            id: In(ids),
        }

        const list = await this.examinationLearningRepo.getManyBy(where)

        if (list.length) this.getEntityByIdOrIds(args, list)

        return ids.length === list.length
    }
}

export function IsExistExaminationLearningDbValidate(validationOptions?: ValidationOptions) {
    return function (object: Object, propertyName: string) {
        baseRegisterDecorator({
            name: 'IsExistExaminationLearningDbValidate',
            target: object.constructor,
            propertyName: propertyName,
            options: validationOptions,
            validator: IsExistExaminationLearningDbValidateConstraint,
        });
    };
}