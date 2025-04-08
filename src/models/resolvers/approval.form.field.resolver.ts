import { Parent, ResolveField, Resolver } from "@nestjs/graphql";
import { ApprovalForm, ApprovalFormField, OfficeOrgChart, OfficeUser } from "../entities";
import { In } from "typeorm";
import { ApprovalFormTableColumn } from "../entities/approval.form.table.column";
import { DataType } from "../entities/profile.info.field";

@Resolver(_of => ApprovalFormField)
export class ApprovalFormFieldFieldResolver {
    constructor() { }

    @ResolveField('columns', _return => [ApprovalFormTableColumn], { nullable: true })
    async consentUsers(
        @Parent() root: ApprovalFormField
    ) {
        if (root.dataType === DataType.Table) {
            return ApprovalFormTableColumn.find({
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