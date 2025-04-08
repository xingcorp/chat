import {
    registerDecorator, ValidationArguments,
    ValidationOptions,
    ValidatorConstraint,
} from "class-validator";
import { RequestContext } from "@common/context/request.context";
import { baseRegisterDecorator, BaseValidateDecoratorConstraint } from "@decorators/validation/base.validate.decorator";
import { Injectable } from "@nestjs/common";
import { CategoryAssetRepo } from "@models/repositories";
import { CheckInPlace } from "@models/entities";
import { Like } from "typeorm";

@ValidatorConstraint({ async: true })
@Injectable()
export class IsExistCheckInDbValidateConstraint extends BaseValidateDecoratorConstraint {

    constructor(private readonly categoryAssetRepo: CategoryAssetRepo) {
        super()
        this.messageKey = 'CheckInBeaconNotFound'
    }

    async checkValidate(secret: string, args: ValidationArguments) {

        const list = await CheckInPlace.findOneBy({
            secrets: Like(`%${secret}%`)
        })

        args.object['place'] = list

        return !!list
    }
}

export function IsExistCheckInDbValidate(validationOptions?: ValidationOptions) {
    return function (object: Object, propertyName: string) {
        baseRegisterDecorator({
            name: 'IsExistCheckInDbValidate',
            target: object.constructor,
            propertyName: propertyName,
            options: validationOptions,
            validator: IsExistCheckInDbValidateConstraint,
        });
    };
}