import {
    ValidationArguments,
    ValidationOptions,
    ValidatorConstraint,
} from "class-validator";
import { WorkProfileRepo } from "@models/repositories";
import { baseRegisterDecorator, BaseValidateDecoratorConstraint } from "@decorators/validation/base.validate.decorator";
import { Injectable } from "@nestjs/common";

@ValidatorConstraint({async: true})
@Injectable()
export class IsUniqueActiveDateWorkProfileDbValidateConstraint extends BaseValidateDecoratorConstraint {

    constructor(private readonly workProfileRepo: WorkProfileRepo) {
        super()
        this.messageKey = 'ActiveDteOfUserWorkProfileMustUnique'
    }

    async checkValidate(date: number | string, args: ValidationArguments) {
        const updateId = args.object['IsUniqueActiveDateWorkProfileDbValidate_updateId']
        const userQuery = args.object['IsUniqueActiveDateWorkProfileDbValidate_userQuery']
        const dateNumber = args.object['IsUniqueActiveDateWorkProfileDbValidate_dateNumber']

        const record = await this.workProfileRepo.findOne({
            relations: ['user', 'info'],
            where: {
                user: userQuery,
                info: {
                    activeDate: new Date(dateNumber ?? date)
                }
            }
        })

        return !record || (updateId && record.id === updateId)
    }
}

export function IsUniqueActiveDateWorkProfileDbValidate(validationOptions?: ValidationOptions) {
    return function (object: Object, propertyName: string) {
        baseRegisterDecorator({
            name: 'IsUniqueActiveDateWorkProfileDbValidate',
            target: object.constructor,
            propertyName: propertyName,
            options: validationOptions,
            validator: IsUniqueActiveDateWorkProfileDbValidateConstraint,
        });
    };
}