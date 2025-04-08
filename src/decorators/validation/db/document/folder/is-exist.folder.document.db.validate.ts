import {
    ValidationArguments,
    ValidationOptions,
    ValidatorConstraint,
} from "class-validator";
import { baseRegisterDecorator, BaseValidateDecoratorConstraint } from "@decorators/validation/base.validate.decorator";
import { Injectable } from "@nestjs/common";
import { FolderDocumentRepo } from "@models/repositories";
import { In } from "typeorm";

@ValidatorConstraint({ async: true })
@Injectable()
export class IsExistFolderDocumentDbValidateConstraint extends BaseValidateDecoratorConstraint {

    constructor(private readonly folderDocumentRepo: FolderDocumentRepo) {
        super()
        this.messageKey = 'DocumentFolderNotFound'
    }

    async checkValidate(ids: string | string[], args: ValidationArguments) {
        if (!Array.isArray(ids)) ids = [ids]
        const where = {
            id: In(ids),
        }

        const list = await this.folderDocumentRepo.getManyBy(where)

        if (list.length) this.getEntityByIdOrIds(args, list)

        return ids.length === list.length
    }
}

export function IsExistFolderDocumentDbValidate(validationOptions?: ValidationOptions) {
    return function (object: Object, propertyName: string) {
        baseRegisterDecorator({
            name: 'IsExistFolderDocumentDbValidate',
            target: object.constructor,
            propertyName: propertyName,
            options: validationOptions,
            validator: IsExistFolderDocumentDbValidateConstraint,
        });
    };
}