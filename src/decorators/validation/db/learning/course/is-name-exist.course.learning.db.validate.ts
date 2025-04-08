import {
    ValidationArguments,
    ValidationOptions,
    ValidatorConstraint,
} from "class-validator";
import { baseRegisterDecorator, BaseValidateDecoratorConstraint } from "@decorators/validation/base.validate.decorator";
import { Injectable } from "@nestjs/common";
import { Not } from "typeorm";
import { CourseLearningRepo } from "@models/repositories";

@ValidatorConstraint({ async: true })
@Injectable()
export class IsNameExistCourseLearningDbValidateConstraint extends BaseValidateDecoratorConstraint {

    constructor(
        private readonly courseLearningRepo: CourseLearningRepo,
    ) {
        super()
        this.messageKey = 'LearningCourseNameExisted'
    }

    async checkValidate(name: string, args: ValidationArguments) {
        let courseId = args.object['courseId']

        const where = { name }

        if (courseId) {
            where['id'] = Not(courseId)
        }

        return !(await this.courseLearningRepo.count({ where }))
    }
}

export function IsNameExistCourseLearningDbValidate(validationOptions?: ValidationOptions) {
    return function (object: Object, propertyName: string) {
        baseRegisterDecorator({
            name: 'IsNameExistCourseLearningDbValidate',
            target: object.constructor,
            propertyName: propertyName,
            options: validationOptions,
            validator: IsNameExistCourseLearningDbValidateConstraint,
        });
    };
}