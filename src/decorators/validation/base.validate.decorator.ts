import {
    registerDecorator,
    ValidationArguments,
    ValidatorConstraint,
    ValidatorConstraintInterface
} from "class-validator";
import { RequestContext } from "@common/context/request.context";
import { ValidateDataType } from "@interceptors/validate-data-type.interceptor";
import { BaseValidateDecoratorConstraintInterface } from "@decorators/validation/base.validate.interface";
import { OfficeErrorMessage } from "@common/office.error";
import { ValidationDecoratorOptions } from "class-validator/types/register-decorator";
import { ValidationOptions } from "class-validator/types/decorator/ValidationOptions";
import { Injectable } from "@nestjs/common";
import { BaseEntity } from "typeorm";

@ValidatorConstraint({async: true})
@Injectable()
export class BaseValidateDecoratorConstraint implements BaseValidateDecoratorConstraintInterface {
    messageKey: string = 'RequiredField';
    validationOptions: ValidationOptions;
    message: string[];

    async checkValidate(value: any, validationArguments?: ValidationArguments): Promise<boolean> {
        return true;
    }

    async validate(value: any, args: ValidationArguments) {
        await this.setValidationOptions(args)

        const valid = await this.checkValidate(value, {
            ...args,
            constraints: args.constraints.slice(0, -1).filter(i => i)
        })

        switch (RequestContext.currentValidateDataType()) {
            case ValidateDataType.BulkUpsert:
                if (!valid && !args.object['errorMessage']) {
                    this.messageKey = (args.constraints.at(-1)?.validationOptions?.message ?? this.messageKey) as string
                    this.message = this.messageKey.split('::')

                    const message = this.message.shift()

                    args.object['errorMessage'] = this.message.length
                        ? OfficeErrorMessage[message](...this.message)
                        : OfficeErrorMessage[message]
                }

                return true
            case ValidateDataType.Default:
            default:
                return valid
        }

    }

    getEntityByCode(args: ValidationArguments, data: BaseEntity) {
        const checkKey = 'Code'
        if (!args.property.includes(checkKey)) return

        const key = args.property.split(checkKey)
        key.pop()

        const entityKey = key.join(checkKey)

        args.object[entityKey] = data
        args.object[entityKey + 'Id'] = data['id']
    }

    getEntityById(args: ValidationArguments, data: BaseEntity) {
        const checkKey = 'Id'
        if (!args.property.includes(checkKey)) return

        const key = args.property.split(checkKey)
        key.pop()

        const entityKey = key.join(checkKey)

        args.object[entityKey] = data
    }

    getEntityByIds(args: ValidationArguments, data: BaseEntity[]) {
        const checkKey = 'Ids'
        if (!args.property.includes(checkKey)) return

        const key = args.property.split(checkKey)
        key.pop()

        const entityKey = key.join(checkKey) + 's'

        args.object[entityKey] = data
    }

    getEntityByIdOrIds(args: ValidationArguments, data: BaseEntity[]) {
        if (args.property.endsWith('Id')) {
            return this.getEntityById(args, data[0])
        }

        return this.getEntityByIds(args, data)
    }

    defaultMessage(args: ValidationArguments) {
        return this.messageKey
    }

    private async setValidationOptions(args: ValidationArguments) {
        const custom = args.constraints.at(-1)
        this.validationOptions = custom?.validationOptions
        custom.validationOptions = custom.validationOptions ?? {message: this.messageKey}
        this.messageKey = custom.validationOptions?.message as string
        this.message = this.messageKey.split('::')
    }
}

export function baseRegisterDecorator(options: ValidationDecoratorOptions) {
    const constraints = options.constraints ?? []
    constraints.push({validationOptions: (options.options ?? null) as ValidationOptions})

    return registerDecorator({
        ...options,
        constraints
    })
}
