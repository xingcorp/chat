import { Parent, ResolveField, Resolver } from "@nestjs/graphql";
import {
    ApprovalForm,
    ApprovalFormGroup, OrgChartApprovalForm,
} from "../entities";
import { Brackets, In } from "typeorm";
import { InjectRepository } from "@nestjs/typeorm";
import { ApprovalFormGroupRepo, OfficeOrgChartRepo, OfficeSysUserRepo, OfficeUserRepo } from "@models/repositories";
import { BRIDGE_TABLE_DB } from "@common/db/bridge-table.db";
import { ObjectStatus } from "@models/entities/profile.info.block";
import { RequestContext } from "@common/context/request.context";

@Resolver(_of => ApprovalFormGroup)
export class ApprovalFormGroupResolver {
    constructor(
        @InjectRepository(ApprovalFormGroupRepo)
        private readonly formGroupRepo: ApprovalFormGroupRepo,
        @InjectRepository(OfficeUserRepo)
        private readonly officeUserRepo: OfficeUserRepo,
        @InjectRepository(OfficeSysUserRepo)
        private readonly officeSysUserRepo: OfficeSysUserRepo,
        @InjectRepository(OfficeOrgChartRepo)
        private readonly orgChartRepository: OfficeOrgChartRepo,
    ) { }

    @ResolveField('forms', _return => [ApprovalForm], { nullable: true })
    async forms(
        @Parent() root: ApprovalFormGroup
    ) {
        try {
            const forms = await this.formGroupRepo.listApprovalFormById(root.id)

            if (!forms.length) return []

            const userId = await RequestContext.currentId()
            const departmentId = await this.officeUserRepo.getDepartmentIdBy({id: userId})

            let accessForms: ApprovalForm[] = []

            if (RequestContext.isNormalUser()) {
                accessForms = await ApprovalForm.createQueryBuilder('ap')
                    .select(['ap.id'])
                    .leftJoinAndMapMany('ap.departments', OrgChartApprovalForm, 'oc', 'oc."formId" = ap.id::text')
                    .leftJoinAndSelect(BRIDGE_TABLE_DB.APPROVAL_FORM_USER, 'wBridge', '"wBridge"."officeApprovalFormsId" = ap.id')
                    .where(new Brackets(db => {
                        db.where(`oc."departmentId"::text IN (:...orgIds)`, {orgIds: [departmentId]})
                            .orWhere(`"wBridge"."officeUsersId" = :userId`, {userId})
                    }))
                    .andWhere({status: ObjectStatus.Active})
                    .getMany()
            } else {

                const query = ApprovalForm.createQueryBuilder('ap')
                    .leftJoinAndMapMany('ap.departments', OrgChartApprovalForm, 'oc', 'oc."formId" = ap.id::text')
                    .where({})

                const orgIds = await this.officeSysUserRepo.getOrgChartIds(RequestContext.currentRequestId())
                if (orgIds) {
                    const ids = await this.orgChartRepository.getAllIdsCurrentAndChild(orgIds)

                    query.andWhere(`oc."departmentId"::text IN (:...orgIds)`, {orgIds: ids})
                }

                accessForms = await query.getMany()
            }

            const accessFormsId = accessForms.map(i => i?.id)

            return ApprovalForm.findBy({
                id: In(forms.map(i => i?.id).filter(i => accessFormsId.includes(i)))
            })
        } catch (e) {
            console.log('ApprovalFormGroupResolver e', e)
            return []
        }
    }
}