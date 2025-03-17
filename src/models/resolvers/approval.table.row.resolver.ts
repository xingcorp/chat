import { Parent, ResolveField, Resolver } from "@nestjs/graphql";
import { ApprovalField, ApprovalForm, ApprovalFormField, OfficeOrgChart, OfficeUser } from "../entities";
import { DataType } from "../entities/profile.info.field";
import { ApprovalTableRow } from "../entities/approval.table.row";
import { ApprovalTableRowData } from "../entities/approval.table.row.data";

@Resolver(_of => ApprovalTableRow)
export class ApprovalTableRowFieldResolver {
    constructor() { }

    @ResolveField('data', _return => [ApprovalTableRowData], { nullable: true })
    async tableRows(
        @Parent() root: ApprovalTableRow
    ) {
        return ApprovalTableRowData.find({
            where: {
                rowId: root.id
            },
            order: {
                order: "ASC"
            }
        })
    }
}