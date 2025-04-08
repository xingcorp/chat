import {
    ValidationArguments,
    ValidationOptions,
    ValidatorConstraint,
} from "class-validator";
import { baseRegisterDecorator, BaseValidateDecoratorConstraint } from "@decorators/validation/base.validate.decorator";
import { Injectable } from "@nestjs/common";
import { In, Not } from "typeorm";
import { CourseLearningRepo } from "@models/repositories";
import { arrayConvertToDistinctAndNotNull } from "@utils/array.utils";

@ValidatorConstraint({ async: true })
@Injectable()
export class IsExistCourseLearningDbValidateConstraint extends BaseValidateDecoratorConstraint {

    constructor(
        private readonly courseLearningRepo: CourseLearningRepo,
    ) {
        super()
        this.messageKey = 'LearningCourseNotFound'
    }

    async checkValidate(ids: string | string[], args: ValidationArguments) {
        if (!Array.isArray(ids)) ids = [ids]
        ids = arrayConvertToDistinctAndNotNull(ids)
        if (!ids.length) return true

        const where = {
            id: In(ids),
        }

        const list = await this.courseLearningRepo.getManyBy(where)

        if (list.length) this.getEntityByIdOrIds(args, list)

        return ids.length === list.length
    }
}

export function IsExistCourseLearningDbValidate(validationOptions?: ValidationOptions) {
    return function (object: Object, propertyName: string) {
        baseRegisterDecorator({
            name: 'IsExistCourseLearningDbValidate',
            target: object.constructor,
            propertyName: propertyName,
            options: validationOptions,
            validator: IsExistCourseLearningDbValidateConstraint,
        });
    };
}