import {
    registerDecorator,
    ValidationOptions,
    ValidatorConstraint,
    ValidatorConstraintInterface,
    ValidationArguments,
} from 'class-validator';
import { OfficeError } from '../../../../common/office.error';
import { OfficeOrgChart } from '../../../../models/entities';

@ValidatorConstraint({ async: true })
class IsOrgChartIdExistConstraint implements ValidatorConstraintInterface {
    async validate(id: string, args: ValidationArguments) {
        const org = await OfficeOrgChart.findOne({ where: { id } });
        if (!org) throw OfficeError.OrgChartNotFound;
        return true;
    }
}

export function IsOrgChartIdExist(validationOptions?: ValidationOptions) {
    return function (object: Object, propertyName: string) {
        registerDecorator({
            target: object.constructor,
            propertyName: propertyName,
            options: validationOptions,
            constraints: [],
            validator: IsOrgChartIdExistConstraint,
        });
    };
}