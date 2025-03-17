import { ValidatorConstraintInterface } from "class-validator";
import { ValidationArguments } from "class-validator/types/validation/ValidationArguments";

export interface BaseValidateDecoratorConstraintInterface extends ValidatorConstraintInterface {
    messageKey: string
    checkValidate(value: any, validationArguments?: ValidationArguments): Promise<boolean> | boolean
}
