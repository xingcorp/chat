import {
    Field,
    Float,
    InputType,
    Int,
    ObjectType,
    OmitType,
    PartialType,
    PickType,
} from "@nestjs/graphql";
import { ValidateIf } from "class-validator";
import { IsExistUserDbValidate } from "@decorators/validation/db/user/is-exist.user.db.validate";
import { IsExistOrgChartDbValidate } from "@decorators/validation/db/org-chart/is-exist.org-chart.db.validate";
import { IsExistAttachmentsIamValidate } from "@decorators/validation/iam/is-exist-attachments.iam.validate";
import {
    IsExistCategoryAssetDbValidate
} from "@decorators/validation/db/asset/category-asset/is-exist.category-asset.db.validate";
import {
    IsExistWarehouseAssetDbValidate
} from "@decorators/validation/db/asset/warehouse-asset/is-exist.warehouse-asset.db.validate";
import { IsExistCodeUserDbValidate } from "@decorators/validation/db/user/is-exist-code.user.db.validate";
import { IsValidDateFormatValidate } from "@decorators/validation/utils/is-valid-date-format.validate";
import { IsCodeExistOrgChartDbValidate } from "@decorators/validation/db/org-chart/is-code-exist.org-chart.db.validate";
import {
    IsExistCodeCategoryAssetDbValidate
} from "@decorators/validation/db/asset/category-asset/is-exist-code.category-asset.db.validate";
import {
    IsExistCodeWarehouseAssetDbValidate
} from "@decorators/validation/db/asset/warehouse-asset/is-exist-code.warehouse-asset.db.validate";
import { DatePeriod, NumberRange } from "@common/args.common";
import { AssetStatus } from "@enum/asset/asset.enum";
import { Transform } from "class-transformer";
import { IsUndefinedValidate } from "@decorators/validation/utils/is-undefined.validate";
import { IsExistCodeAssetDbValidate } from "@decorators/validation/db/asset/asset/is-exist-code.asset.db.validate";
import { IsDataSameOrgAssetDbValidate } from "@decorators/validation/db/asset/is-data-same-org.asset.db.validate";
import { OfficeOrgChart } from "@models/entities";
import { IsUndefinedAnotherValidate } from "@decorators/validation/utils/is-undefined-another.validate";

@InputType()
export class AssetCreateInput {
    department?: OfficeOrgChart

    @Field(_type => String, {nullable: false, description: 'ten tai san'})
    @IsDataSameOrgAssetDbValidate()
    name: string

    @Field(_type => Float, {nullable: false, description: 'so luong'})
    quantity: number

    @Field(_type => String, {nullable: true, description: 'serial'})
    serial: string

    @Field(_type => String, {nullable: true, description: 'mo ta'})
    description: string

    @Field(_type => String, {nullable: false, description: 'danh muc tai san'})
    @IsExistCategoryAssetDbValidate()
    categoryId: string

    @Field(_type => Float, {nullable: false, description: 'Ngày mua'})
    purchaseAt: number

    @Field(_type => Int, {nullable: true, description: 'thoi gian bao hanh theo thang'})
    warrantyByMonth: number

    @Field(_type => Float, {nullable: true, description: 'han bao hanh'})
    @ValidateIf(o => o.assignedDepartmentId)
    @IsUndefinedAnotherValidate('assignedUserId', {
        message: 'AssetOnlyOneAssignData'
    })
    warrantyExpiredAt: number

    @Field(_type => String, {nullable: true, description: 'nha cung cap'})
    @ValidateIf(o => o.managementDepartmentId)
    @IsUndefinedAnotherValidate('managementUserId', {
        message: 'AssetOnlyOneManagementData'
    })
    providerText: string

    @Field(_type => String, {nullable: true, description: 'kho luu tru'})
    @ValidateIf(o => o.warehouseId)
    @IsExistWarehouseAssetDbValidate()
    warehouseId: string

    @Field(_type => String, {nullable: true})
    @ValidateIf(o => o.managementUserId)
    @IsExistUserDbValidate()
    managementUserId: string

    @Field(_type => String, {nullable: true, description: 'Phòng ban'})
    @ValidateIf(o => o.managementDepartmentId)
    @IsExistOrgChartDbValidate()
    managementDepartmentId: string

    @Field(_type => String, {nullable: true})
    @ValidateIf(o => o.assignedUserId)
    @IsExistUserDbValidate()
    assignedUserId: string

    @Field(_type => String, {nullable: true, description: 'Phòng ban'})
    @ValidateIf(o => o.assignedDepartmentId)
    @IsExistOrgChartDbValidate()
    assignedDepartmentId: string

    @Field(_type => Float, {nullable: true, description: 'gia mua'})
    price: string

    @Field(_type => Int, {nullable: true, description: 'khau hao'})
    monthlyDepreciation: number

    @Field(() => [String], {nullable: true, description: 'anh tai san'})
    @ValidateIf(o => o.imageIds)
    @IsExistAttachmentsIamValidate()
    imageIds: string[]

    @Field(() => [String], {nullable: true, description: 'file dinh kem'})
    @ValidateIf(o => o.attachmentIds)
    @IsExistAttachmentsIamValidate()
    attachmentIds: string[]
}

@InputType()
export class AssetUpdateInput extends PartialType(OmitType(AssetCreateInput, ['quantity', 'categoryId'])) {
    @Field(_type => String, {nullable: false})
    id: string
}

@InputType()
export class ManagementAssetFilter {
    @Field(() => Int, {nullable: true})
    page: number

    @Field(() => Int, {nullable: true})
    size: number

    @Field({ nullable: true })
    keyword: string

    @Field(_type => String, {nullable: true, description: 'danh muc tai san'})
    categoryId: string

    @Field(() => AssetStatus, {nullable: true})
    status: AssetStatus

    @Field(_type => DatePeriod, { nullable: true })
    purchaseDate: DatePeriod

    @Field(() => Int, {nullable: true})
    warrantyByMonth: number

    /*Todo:*/
    @Field(_type => DatePeriod, { nullable: true })
    handoverDate: DatePeriod

    @Field(_type => NumberRange, { nullable: true })
    priceRange: NumberRange

    @Field(_type => String, {nullable: true, description: 'Phòng ban'})
    managementDepartmentId: string

    @Field(_type => String, {nullable: true, description: 'Phòng ban'})
    assignedDepartmentId: string
}

@InputType()
@ObjectType()
export class AssetBulkUpsertInput extends PartialType(
    PickType(AssetCreateInput, ['name', 'serial', 'description', 'providerText'])
) {
    errorMessage?: string

    @Field(_type => String, {nullable: true})
    @ValidateIf(o => o.assetCode)
    @IsExistCodeAssetDbValidate()
    @IsUndefinedAnotherValidate('categoryCode', {
        message: 'CannotUpdateField::Danh mục tài sản'
    })
    assetCode: string

    assetId?: string

    @Field(_type => String, {nullable: true, description: 'khau hao'})
    @Transform(({value}) => parseInt(value))
    monthlyDepreciation: number

    @Field(() => String, {nullable: true})
    @Transform(({value}) => parseInt(value))
    warrantyByMonth: number

    @Field(() => String, {nullable: true})
    @Transform(({value}) => parseInt(value))
    @ValidateIf(o => o.assetCode)
    @IsUndefinedValidate({
        message: 'AssetNotHaveQuantity'
    })
    quantity: number

    @Field(() => String, {nullable: true})
    @Transform(({value}) => parseFloat(value))
    price: string

    @Field(_type => String, {nullable: true, description: 'Ngày mua'})
    @ValidateIf(o => o.purchaseDate)
    @IsValidDateFormatValidate('DD/MM/yyyy', {
        message: 'WrongFormatField::Ngày mua'
    })
    purchaseDate: string

    purchaseAt?: number

    @Field(_type => String, {nullable: true, description: 'Hạn bảo hảnh'})
    @ValidateIf(o => o.warrantyExpiredDate)
    @IsValidDateFormatValidate('DD/MM/yyyy', {
        message: 'WrongFormatField::Hạn bảo hảnh'
    })
    warrantyExpiredDate: string

    warrantyExpiredAt?: number

    @Field(_type => String, {nullable: true})
    @ValidateIf(o => o.categoryCode)
    @IsExistCodeCategoryAssetDbValidate()
    categoryCode: string

    categoryId?: string

    @Field(_type => String, {nullable: true})
    @ValidateIf(o => o.warehouseCode)
    @IsExistCodeWarehouseAssetDbValidate()
    warehouseCode: string

    warehouseId?: string

    @Field(_type => String, {nullable: true})
    @ValidateIf(o => o.managementUserCode)
    @IsExistCodeUserDbValidate()
    managementUserCode: string

    managementUserId?: string

    @Field(_type => String, {nullable: true})
    @ValidateIf(o => o.managementDepartmentCode)
    @IsCodeExistOrgChartDbValidate()
    managementDepartmentCode: string

    managementDepartmentId?: string


    @Field(_type => String, {nullable: true})
    @ValidateIf(o => o.assignedUserCode)
    @IsExistCodeUserDbValidate()
    assignedUserCode: string

    assignedUserId?: string

    @Field(_type => String, {nullable: true})
    @ValidateIf(o => o.assignedDepartmentCode)
    @IsCodeExistOrgChartDbValidate()
    assignedDepartmentCode: string

    assignedDepartmentId?: string
}