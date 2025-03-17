import { Parent, ResolveField, Resolver } from "@nestjs/graphql";
import { ApprovalField, ApprovalForm, ApprovalFormField, OfficeOrgChart, OfficeUser } from "../entities";
import { DataType } from "../entities/profile.info.field";
import { ApprovalTableRow } from "../entities/approval.table.row";
import { ApprovalTableRowData } from "../entities/approval.table.row.data";
import { ApprovalService } from "src/modules/graphql/approval/approval.service";
import { Inject, forwardRef } from "@nestjs/common";

@Resolver(_of => ApprovalField)
export class ApprovalFieldFieldResolver {
    constructor(
        @Inject(forwardRef(() => ApprovalService))
        private readonly approvalService: ApprovalService
    ) { }

    @ResolveField('tableColumns', _return => [String], { nullable: true })
    async tableColumns(
        @Parent() root: ApprovalField
    ) {
        const columns = await this.approvalService.getColumnNameByTableField(root.id)
        if (columns) {
            return columns.map(col => col.name)
        }
        
        return null
    }

    @ResolveField('tableRows', _return => [ApprovalTableRow], { nullable: true })
    async tableRows(
        @Parent() root: ApprovalField
    ) {
        if (root.dataType === DataType.Table) {
            return ApprovalTableRow.find({
                where: {
                    fieldId: root.id
                },
                order: {
                    order: "ASC"
                }
            })
        }

        return null
    }
}