import {
    registerDecorator,
    ValidationOptions,
    ValidatorConstraint,
    ValidatorConstraintInterface,
    ValidationArguments,
} from 'class-validator';
import { OfficeError } from '../../../../common/office.error';
import { OfficeUser } from '../../../../models/entities';

@ValidatorConstraint({ async: true })
class IsEmployeeIdExistConstraint implements ValidatorConstraintInterface {
    async validate(id: string, args: ValidationArguments) {
        const meetingRoom = await OfficeUser.findOne({ where: { id } });
        if (!meetingRoom) throw OfficeError.EmployeeNotFound;
        return true;
    }
}

export function IsEmployeeIdExist(validationOptions?: ValidationOptions) {
    return function (object: Object, propertyName: string) {
        registerDecorator({
            target: object.constructor,
            propertyName: propertyName,
            options: validationOptions,
            constraints: [],
            validator: IsEmployeeIdExistConstraint,
        });
    };
}