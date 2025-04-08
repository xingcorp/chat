import {
    ValidationArguments,
    ValidationOptions,
    ValidatorConstraint,
} from "class-validator";
import { baseRegisterDecorator, BaseValidateDecoratorConstraint } from "@decorators/validation/base.validate.decorator";
import { Injectable } from "@nestjs/common";
import { ApprovalStepRepo, OfficeApprovalRepo } from "@models/repositories";
import { RequestContext } from "@common/context/request.context";

@ValidatorConstraint({ async: true })
@Injectable()
export class IsCanAddSubscriberApprovalDbValidateConstraint extends BaseValidateDecoratorConstraint {

    constructor(
        private readonly approvalRepo: OfficeApprovalRepo,
        private readonly approvalStepRepo: ApprovalStepRepo,
    ) {
        super()
        this.messageKey = 'NotAllow'
    }

    async checkValidate(id: string, args: ValidationArguments) {
        const data = await this.approvalRepo.getOneBy({id})

        if (!data) return false

        const userId = await RequestContext.currentId()
        const {allRelevantIds} = await this.approvalStepRepo.getInfoListUserIdOfStepByApprovalId(data.id)

        const check = [
            ...this.approvalRepo.getAllUserIdRelative(data),
            ...allRelevantIds
        ].some(i => i === userId)

        if (check) this.getEntityById(args, data)

        return check
    }
}

export function IsCanAddSubscriberApprovalDbValidate(validationOptions?: ValidationOptions) {
    return function (object: Object, propertyName: string) {
        baseRegisterDecorator({
            name: 'IsCanAddSubscriberApprovalDbValidate',
            target: object.constructor,
            propertyName: propertyName,
            options: validationOptions,
            validator: IsCanAddSubscriberApprovalDbValidateConstraint,
        });
    };
}