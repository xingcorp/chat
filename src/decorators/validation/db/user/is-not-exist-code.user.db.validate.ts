import {
    ValidationArguments,
    ValidationOptions,
    ValidatorConstraint,
} from "class-validator";
import { Injectable } from "@nestjs/common";
import { OfficeUserRepo } from "@models/repositories";
import { baseRegisterDecorator, BaseValidateDecoratorConstraint } from "@decorators/validation/base.validate.decorator";
import { DataSource } from "typeorm";

@ValidatorConstraint({async: true})
@Injectable()
export class IsNotExistCodeUserDbValidateConstraint extends BaseValidateDecoratorConstraint {

    constructor(
        private dataSource: DataSource,
        private officeUserRepo: OfficeUserRepo
    ) {
        super()
        this.messageKey = 'EmployeeCodeIsExisted'
    }

    async checkValidate(code: string, args: ValidationArguments) {
        let userId = null

        if (args.constraints[0]) {
            const {key, query} = args?.constraints[0] as IsNotExistCodeUserDbValidatePropertyType
            const checkValue = (args.object as any)[key]

            userId = await query(checkValue)

        }

        if ((args.object as any)['userId']) userId = (args.object as any)['userId']
        else if ((args.object as any)['user']) userId = (args.object as any)['user'].id

        return !(await this.officeUserRepo.getByWithoutUserById({code}, userId))
    }
}

type IsNotExistCodeUserDbValidatePropertyType = {
    key: string,
    query: (...param: any[]) => {}
}


export function IsNotExistCodeUserDbValidate(property?: IsNotExistCodeUserDbValidatePropertyType, validationOptions?: ValidationOptions) {
    return function (object: Object, propertyName: string) {
        baseRegisterDecorator({
            name: 'IsNotExistCodeUserDbValidate',
            target: object.constructor,
            propertyName: propertyName,
            constraints: [property],
            options: validationOptions,
            validator: IsNotExistCodeUserDbValidateConstraint,
        });
    };
}