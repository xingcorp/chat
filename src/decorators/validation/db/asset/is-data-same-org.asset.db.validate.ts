import {
    ValidationArguments,
    ValidationOptions,
    ValidatorConstraint,
} from "class-validator";
import { Injectable } from "@nestjs/common";
import {
    AssetRepo,
    CategoryAssetRepo,
    OfficeOrgChartRepo,
    OfficeUserRepo,
    WarehouseAssetRepo
} from "@models/repositories";
import { baseRegisterDecorator, BaseValidateDecoratorConstraint } from "@decorators/validation/base.validate.decorator";
import { arrayConvertToDistinctAndNotNull } from "@utils/array.utils";

@ValidatorConstraint({async: true})
@Injectable()
export class IsDataSameOrgAssetDbValidateConstraint extends BaseValidateDecoratorConstraint {

    constructor(
        private readonly assetRepo: AssetRepo,
        private readonly categoryAssetRepo: CategoryAssetRepo,
        private readonly warehouseAssetRepo: WarehouseAssetRepo,
        private readonly userRepo: OfficeUserRepo,
        private readonly orgChartRepo: OfficeOrgChartRepo,
    ) {
        super()
        this.messageKey = 'AssetDataNotSameOrg'
    }

    async checkValidate(name: string, args: ValidationArguments) {
        const cateOrgId = await this.categoryAssetRepo.getOrgIdById(args.object['categoryId'])
        const wareOrgId = await this.warehouseAssetRepo.getOrgIdById(args.object['warehouseId'])

        let manageUserOrgId = null
        if (args.object['managementUserId'] || args.object['managementUserCode']) {
            const where = args.object['managementUserId'] ? {id: args.object['managementUserId']} : {code: args.object['managementUserCode']}
            const departmentId = await this.userRepo.getDepartmentIdBy(where)
            manageUserOrgId = await this.orgChartRepo.getRootIdOfDepartmentId(departmentId)
        }

        let assignedUserOrgId = null
        if (args.object['assignedUserId'] || args.object['assignedUserCode']) {
            const where = args.object['assignedUserId'] ? {id: args.object['assignedUserId']} : {code: args.object['assignedUserCode']}
            const departmentId = await this.userRepo.getDepartmentIdBy(where)
            assignedUserOrgId = await this.orgChartRepo.getRootIdOfDepartmentId(departmentId)
        }

        let manageDepartmentId = null
        if (args.object['managementDepartmentId']) {
            manageDepartmentId = await this.orgChartRepo.getRootIdOfDepartmentId(args.object['managementDepartmentId'])
        } else if (args.object['managementDepartmentCode']) {
            const manageDepartment = await this.orgChartRepo.getBy({code: args.object['managementDepartmentCode']})
            manageDepartmentId = manageDepartment?.id
        }

        let assignedDepartmentId = null
        if (args.object['assignedDepartmentId']) {
            assignedDepartmentId = await this.orgChartRepo.getRootIdOfDepartmentId(args.object['assignedDepartmentId'])
        } else if (args.object['assignedDepartmentCode']) {
            const assignedDepartment = await this.orgChartRepo.getBy({code: args.object['assignedDepartmentCode']})
            assignedDepartmentId = assignedDepartment?.id
        }

        const orgIds = arrayConvertToDistinctAndNotNull([
            cateOrgId,
            wareOrgId,
            manageUserOrgId,
            assignedUserOrgId,
            manageDepartmentId,
            assignedDepartmentId
        ])

        const pass = orgIds.length === 1

        if (pass) {
            args.object['department'] = await this.orgChartRepo.getBy({id: orgIds[0]})
        }

        return pass
    }
}

export function IsDataSameOrgAssetDbValidate(validationOptions?: ValidationOptions) {
    return function (object: Object, propertyName: string) {
        baseRegisterDecorator({
            name: 'IsDataSameOrgAssetDbValidate',
            target: object.constructor,
            propertyName: propertyName,
            options: validationOptions,
            validator: IsDataSameOrgAssetDbValidateConstraint,
        });
    };
}