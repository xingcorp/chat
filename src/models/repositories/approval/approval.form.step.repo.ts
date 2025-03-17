import { Injectable } from "@nestjs/common";
import { ArrayContains, Brackets, DataSource, ILike, In, IsNull, Not, Repository } from "typeorm";
import { ApprovalFormStep, OfficeOrgChart, OrgChartApprovalForm } from "@models/entities";
import { ApprovalAction } from "@models/entities/approval.form";
import { OfficeUserRepo } from "@repositories/profile.user.repo";
import { pluck } from "@utils/object.utils";

@Injectable()
export class ApprovalFormStepRepo extends Repository<ApprovalFormStep> {
    constructor(
        private dataSource: DataSource,
        private officeUserRepo: OfficeUserRepo,
    ) {
        super(ApprovalFormStep, dataSource.createEntityManager());
    }

    async getAllOfUserByAction(userId: string, action: ApprovalAction) {
        const userDepartmentsManagement = await this.officeUserRepo.getDepartmentsManagementById(userId)
        const userDepartmentsManagementId = userDepartmentsManagement.map(i => i.id)

        const approvalByLevel = await OrgChartApprovalForm.findBy({
            departmentId: In(userDepartmentsManagementId)
        })
        const approvalByLevelFormIds = approvalByLevel.map(id => id.formId)

        return pluck(await this.createQueryBuilder('qb')
                .leftJoinAndMapOne('qb.department', OfficeOrgChart, 'dd', 'dd.id::text = qb."departmentId"::text')
                .where({action})
                .andWhere(new Brackets(db => {
                    db
                        .where({
                            approveBy: ArrayContains([userId])
                        })
                        .orWhere({
                            departmentId: In(userDepartmentsManagementId)
                        })
                        .orWhere({
                            approverLevel: Not(IsNull()),
                            formId: In(approvalByLevelFormIds)
                        })
                }))
                .getMany(),
            'formId'
        )
    }
}