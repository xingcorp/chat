import {
    ValidationArguments,
    ValidationOptions,
    ValidatorConstraint,
} from "class-validator";
import { baseRegisterDecorator, BaseValidateDecoratorConstraint } from "@decorators/validation/base.validate.decorator";
import { Injectable } from "@nestjs/common";
import { ApprovalFormRepo, OfficeApprovalRepo } from "@models/repositories";
import { ApprovalSource } from "@models/entities/approval";

@ValidatorConstraint({ async: true })
@Injectable()
export class IsValidSubscriberListApprovalDbValidateConstraint extends BaseValidateDecoratorConstraint {

    constructor(
        private readonly approvalRepo: OfficeApprovalRepo,
        private readonly approvalFormRepo: ApprovalFormRepo,
    ) {
        super()
        this.messageKey = 'ApprovalCanNotRemoveDefaultSubscriber'
    }

    async checkValidate(id: string, args: ValidationArguments) {
        const data = await this.approvalRepo.findOneBy({id})

        if (!data) return false
        if (data.source === ApprovalSource.Blank) return true

        const [name] = args.constraints;
        const subscriberIds = (args.object as any)[name] as string[];

        // const add = data.subscriberIds ? subscriberIds.filter(i => !data.subscriberIds.includes(i)) : subscriberIds
        const remove = Array.isArray(data.subscriberIds)
            ? subscriberIds ? data.subscriberIds?.filter(i => !subscriberIds.includes(i)) : data.subscriberIds
            : []

        const form = await this.approvalFormRepo.findOneBy({id: data.formId})

        return !!form && (!form.subscriberIds || !form?.subscriberIds.some(subscriberId => remove.includes(subscriberId)))
    }
}

export function IsValidSubscriberListApprovalDbValidate(property: string, validationOptions?: ValidationOptions) {
    return function (object: Object, propertyName: string) {
        baseRegisterDecorator({
            name: 'IsValidSubscriberListApprovalDbValidate',
            target: object.constructor,
            propertyName: propertyName,
            constraints: [property],
            options: validationOptions,
            validator: IsValidSubscriberListApprovalDbValidateConstraint,
        });
    };
}