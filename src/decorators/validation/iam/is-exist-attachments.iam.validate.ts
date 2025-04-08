import {
    ValidationArguments,
    ValidationOptions,
    ValidatorConstraint,
} from "class-validator";
import { RequestContext } from "@common/context/request.context";
import { forwardRef, Inject, Injectable } from "@nestjs/common";
import { StorageService } from "@core/storage/storage.service";
import { baseRegisterDecorator, BaseValidateDecoratorConstraint } from "@decorators/validation/base.validate.decorator";

@ValidatorConstraint({async: true})
@Injectable()
export class IsExistAttachmentsIamValidateConstraint extends BaseValidateDecoratorConstraint {

    constructor(@Inject(forwardRef(() => StorageService)) private readonly storageService: StorageService) {
        super()
        this.messageKey = 'FileNotExisted'
    }

    async checkValidate(attachmentIds: string | string[], args: ValidationArguments) {
        if (!attachmentIds || (Array.isArray(attachmentIds) && !attachmentIds.length)) return true
        const [file] = args.constraints;

        if (!Array.isArray(attachmentIds)) attachmentIds = [attachmentIds]
        args.object[file] = []

        for (const attachmentId of attachmentIds) {
            const {data, error} = await this.storageService.getFileDetail(RequestContext.currentToken(), attachmentId)
            if (error || !data) return false
            args.object[file].push(data)
        }

        return true
    }
}

export function IsExistAttachmentsIamValidate(property?: string, validationOptions?: ValidationOptions) {
    return function (object: Object, propertyName: string) {
        baseRegisterDecorator({
            name: 'IsExistAttachmentsIamValidate',
            target: object.constructor,
            propertyName: propertyName,
            constraints: [property ?? 'file'],
            options: validationOptions,
            validator: IsExistAttachmentsIamValidateConstraint,
        });
    };
}