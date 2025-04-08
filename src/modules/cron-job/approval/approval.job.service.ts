import { Injectable } from '@nestjs/common';
import { Timeout } from "@nestjs/schedule";
import { ApprovalField, ApprovalStep, OfficeApproval } from "@models/entities";
import { ApprovalSource } from "@models/entities/approval";
import { In, IsNull, MoreThanOrEqual } from "typeorm";
import { ApprovalAction } from "@models/entities/approval.form";

@Injectable()
export class ApprovalJobService {
    constructor() {
    }

    /*in progress*/
    @Timeout(10000)
    async removeFieldUnNeeded() {
        try {
            console.log('removeFieldUnNeeded start')
            let fields: ApprovalField[]

            do {
                fields = await ApprovalField.createQueryBuilder('qb')
                    .leftJoinAndMapOne('qb.approval', OfficeApproval, 'approval', 'qb."approvalId"::text = approval.id::text')
                    .where({
                        order: MoreThanOrEqual(3),
                    })
                    .orderBy('qb."createdAt"', 'DESC')
                    .andWhere(`approval.source = :source`, {source: ApprovalSource.Blank})
                    .limit(100)
                    .getMany();

                console.log('removeFieldUnNeeded progress', fields.length)

                await ApprovalField.softRemove(fields)

            } while (fields.length)

            console.log('removeFieldUnNeeded end')
        } catch (e) {
            console.log('removeFieldUnNeeded error', e)
        }
    }
    /*in progress*/
    @Timeout(5000)
    async addDataForNewField() {
        try {
            console.log('addDataForNewField start')
            let steps: ApprovalStep[]

            /*approval*/
            do {
                steps = await ApprovalStep.createQueryBuilder('qb')
                    .leftJoinAndMapOne(
                        'qb.current',
                        ApprovalStep,
                        'current',
                        'qb."approvalId"::text = current."approvalId"::text AND current.currentStep is TRUE AND current."approvalAction" = :action',
                        {
                            action: ApprovalAction.Approve
                        }
                    )
                    .leftJoinAndMapOne(
                        'qb.min',
                        ApprovalStep,
                        'min',
                        'qb."approvalId"::text = min."approvalId"::text ' +
                        'AND min.order = (SELECT MIN("order") FROM "office"."office-approval-steps" ocid WHERE qb."approvalId"::text = ocid."approvalId"::text AND ocid."actionAt" is NULL)'
                    )
                    .where(`qb."canAction" is FALSE`)
                    .andWhere(`qb.action is NULL`)
                    .andWhere(`min.order <= current.order`)
                    .andWhere(`min.order = qb.order`)
                    .orderBy('qb."createdAt"', 'DESC')
                    .limit(100)
                    .getMany();

                console.log('addDataForNewField progress1', steps.length)

                await ApprovalStep.update(
                    {id: In(steps.map(i => i.id))},
                    {canAction: true})

            } while (steps.length)

            /*consent*/
            do {
                steps = await ApprovalStep.createQueryBuilder('qb')
                    .leftJoinAndMapOne(
                        'qb.current',
                        ApprovalStep,
                        'current',
                        'qb."approvalId"::text = current."approvalId"::text AND current.currentStep is TRUE AND current."approvalAction" = :action',
                        {
                            action: ApprovalAction.Consent
                        }
                    )
                    .where(`qb."canAction" is FALSE`)
                    .andWhere(`qb.action is NULL`)
                    .andWhere(`qb.order <= current.order`)
                    .orderBy('qb."createdAt"', 'DESC')
                    .limit(100)
                    .getMany();

                console.log('addDataForNewField progress2', steps.length)

                await ApprovalStep.update(
                    {id: In(steps.map(i => i.id))},
                    {canAction: true, currentStep: false})

                for (const step of steps) {
                    const approvalStep = await ApprovalStep.findOne({
                        where: {
                            approvalId: step.approvalId,
                            approvalAction: ApprovalAction.Approve,
                            action: IsNull()
                        },
                        order: {
                            order: 'ASC'
                        }
                    })

                    if (approvalStep) {
                        approvalStep.currentStep = true
                        approvalStep.canAction = true
                        await approvalStep.save()
                    }
                }

            } while (steps.length)

            console.log('addDataForNewField end')
        } catch (e) {
            console.log('addDataForNewField error', e)
        }
    }

}
