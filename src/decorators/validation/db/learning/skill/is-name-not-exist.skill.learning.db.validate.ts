import {
    ValidationArguments,
    ValidationOptions,
    ValidatorConstraint,
} from "class-validator";
import { baseRegisterDecorator, BaseValidateDecoratorConstraint } from "@decorators/validation/base.validate.decorator";
import { Injectable } from "@nestjs/common";
import { Not } from "typeorm";
import { SkillLearningRepo } from "@models/repositories";

@ValidatorConstraint({ async: true })
@Injectable()
export class IsNameNotExistSkillLearningDbValidateConstraint extends BaseValidateDecoratorConstraint {

    constructor(
        private readonly skillLearningRepo: SkillLearningRepo,
    ) {
        super()
        this.messageKey = 'LearningSkillNameExisted'
    }

    async checkValidate(name: string, args: ValidationArguments) {
        let _thisId = args.object['IsNameNotExistSkillLearningDbValidate_skillId']

        const where = {name}

        if (_thisId) {
            where['id'] = Not(_thisId)
        }

        return !(await this.skillLearningRepo.count({where}))
    }
}

export function IsNameNotExistSkillLearningDbValidate(validationOptions?: ValidationOptions) {
    return function (object: Object, propertyName: string) {
        baseRegisterDecorator({
            name: 'IsNameNotExistSkillLearningDbValidate',
            target: object.constructor,
            propertyName: propertyName,
            options: validationOptions,
            validator: IsNameNotExistSkillLearningDbValidateConstraint,
        });
    };
}