import {
    ValidationArguments,
    ValidationOptions,
    ValidatorConstraint,
} from "class-validator";
import { baseRegisterDecorator, BaseValidateDecoratorConstraint } from "@decorators/validation/base.validate.decorator";
import { Injectable } from "@nestjs/common";
import { getMetadataArgsStorage } from "typeorm";

@ValidatorConstraint({ async: true })
@Injectable()
export class IsPropertyNameExistConstraint extends BaseValidateDecoratorConstraint {

    constructor() {
        super();
        this.messageKey = 'PropertyNameNotExist';
    }

    async checkValidate(property: string, args: ValidationArguments) {
        const entityClass = args.constraints[0];

        if (!entityClass) {
            throw new Error("Entity class is not set");
        }

        // Get metadata from TypeORM entity
        const metadata = getMetadataArgsStorage().columns.filter(
            column => column.target === entityClass
        );

        // Extract column names
        const propertyNames = metadata.map(column => column.propertyName);

        // Add relation names
        const relations = getMetadataArgsStorage().relations.filter(
            relation => relation.target === entityClass
        );
        propertyNames.push(...relations.map(relation => relation.propertyName));

        return propertyNames.includes(property);
    }
}

export function IsPropertyNameExistValidate(entityClass: any, validationOptions?: ValidationOptions) {
    return function (object: Object, propertyName: string) {
        baseRegisterDecorator({
            name: 'IsPropertyNameExistValidate',
            target: object.constructor,
            propertyName: propertyName,
            options: validationOptions,
            constraints: [entityClass],
            validator: IsPropertyNameExistConstraint
        });
    };
}
