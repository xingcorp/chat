import {
    ValidationArguments,
    ValidationOptions,
    ValidatorConstraint,
} from "class-validator";
import { baseRegisterDecorator, BaseValidateDecoratorConstraint } from "@decorators/validation/base.validate.decorator";
import { Injectable } from "@nestjs/common";
import { Not } from "typeorm";
import { CourseLearningRepo } from "@repositories/learning/course.learning.repo";

@ValidatorConstraint({ async: true })
@Injectable()
export class IsCodeExistCourseLearningDbValidateConstraint extends BaseValidateDecoratorConstraint {

    constructor(
        private readonly courseLearningRepo: CourseLearningRepo,
    ) {
        super()
        this.messageKey = 'LearningCourseCodeExisted'
    }

    async checkValidate(code: string, args: ValidationArguments) {
        let courseId = args.object['courseId']

        const where = { code }

        if (courseId) {
            where['id'] = Not(courseId)
        }
        
        return !(await this.courseLearningRepo.count({ where }))
    }
}

export function IsCodeExistCourseLearningDbValidate(validationOptions?: ValidationOptions) {
    return function (object: Object, propertyName: string) {
        baseRegisterDecorator({
            name: 'IsCodeNotExistCourseLearningDbValidate',
            target: object.constructor,
            propertyName: propertyName,
            options: validationOptions,
            validator: IsCodeExistCourseLearningDbValidateConstraint,
        });
    };
}