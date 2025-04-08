import {
    registerDecorator, ValidationArguments,
    ValidationOptions,
    ValidatorConstraint,
} from "class-validator";
import { OfficeInfoBlockRepo, OfficeInfoFieldRepo, WorkProfileRepo } from "@models/repositories";
import { baseRegisterDecorator, BaseValidateDecoratorConstraint } from "@decorators/validation/base.validate.decorator";
import { Injectable } from "@nestjs/common";
import {
    WorkProfileAction,
    WorkProfileChangeType,
    WorkProfileChangeTypeExplain
} from "@enum/work-profile/work-profile.enum";
import { InfoField } from "@models/entities";
import { enumGetKey } from "@utils/enum.utils";

@ValidatorConstraint({async: true})
@Injectable()
export class IsValidMetadataWorkProfileDbValidateConstraint extends BaseValidateDecoratorConstraint {
    private defaultFields: InfoField[];
    private resignFields: InfoField[];
    private keyList: string[];

    constructor(
        private readonly workProfileRepo: WorkProfileRepo,
        private readonly officeInfoBlockRepo: OfficeInfoBlockRepo,
        private readonly officeInfoFieldRepo: OfficeInfoFieldRepo,
    ) {
        super()
        this.messageKey = 'UserWorkProfileMetadataWrongInput'
    }

    async checkValidate(metadata: JSON, args: ValidationArguments) {
        let check = true
        let block = await this.officeInfoBlockRepo.getWorkProfileByOrgId(process.env.K_ORG_ID)
        const workProfileType = this.getWorkTypeChange(args.object)

        this.defaultFields = await this.officeInfoFieldRepo.getWorkProfileDefaultFieldByBlockId(block.id)
        this.resignFields = await this.officeInfoFieldRepo.getWorkProfileResignFieldByBlockId(block.id)
        this.keyList = Object.keys(metadata).filter(i => metadata[i])

        switch (workProfileType) {
            case WorkProfileAction.Remove:
                check = this.checkValidateRemoveUserMetadata()
                break
            default:
                check = this.checkValidateDefaultUserMetadata()
        }

        return check
    }

    private getWorkTypeChange(object: object) {
        let type = object['type']

        if (!type && object['typeText']) {
            type = enumGetKey(WorkProfileChangeTypeExplain, object['typeText'])
        }

        switch (type) {
            case WorkProfileChangeType.NewRecruitment:
                return WorkProfileAction.Create
            case WorkProfileChangeType.QuittingTransfer:
                return WorkProfileAction.Remove
            default:
                return WorkProfileAction.Update
        }
    }

    private checkValidateRemoveUserMetadata() {
        if (
            this.defaultFields.map(i => i.code).some(i => this.keyList.includes(i))
            || this.resignFields.filter(i => i.required).map(i => i.code).some(i => !this.keyList.includes(i))
        ) {
            return false
        }
    }

    private checkValidateDefaultUserMetadata() {
        if (
            this.defaultFields.filter(i => i.required).map(i => i.code).some(i => !this.keyList.includes(i))
            || this.resignFields.map(i => i.code).some(i => this.keyList.includes(i))
        ) {
            return false
        }
    }
}

export function IsValidMetadataWorkProfileDbValidate(validationOptions?: ValidationOptions) {
    return function (object: Object, propertyName: string) {
        baseRegisterDecorator({
            name: 'IsValidMetadataWorkProfileDbValidate',
            target: object.constructor,
            propertyName: propertyName,
            options: validationOptions,
            validator: IsValidMetadataWorkProfileDbValidateConstraint,
        });
    };
}