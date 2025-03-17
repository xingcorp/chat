import { Injectable } from "@nestjs/common";
import { ArrayContains, DataSource, In, IsNull, LessThan, MoreThan, Not, Repository } from "typeorm";
import { ApprovalStep } from "@models/entities";
import { ApprovalProcessAction } from "@models/entities/approval.step";
import { arrayConvertToDistinctAndNotNull } from "@utils/array.utils";
import { InjectRepository } from "@nestjs/typeorm";
import { OfficeUserRepo } from "@models/repositories";
import { RequestContext } from "@common/context/request.context";
import { ApprovalAction } from "@models/entities/approval.form";

enum Position {Past, Present, Future}

@Injectable()
export class ApprovalStepRepo extends Repository<ApprovalStep> {
    constructor(
        private dataSource: DataSource,
        @InjectRepository(OfficeUserRepo)
        private readonly officeUserRepo: OfficeUserRepo,
    ) {
        super(ApprovalStep, dataSource.createEntityManager());
    }

    async getAllStepByApprovalId(approvalId: string) {
        return this.find({
            where: {
                approvalId
            },
            order: {
                actionAt: "ASC",
                order: "ASC"
            },
        })
    }

    async getAllInactionStepByApprovalId(approvalId: string) {
        return this.find({
            where: {
                approvalId,
                actionAt: IsNull()
            },
            order: {
                order: "ASC"
            },
        })
    }

    async getAllActionStepByApprovalId(approvalId: string) {
        return this.find({
            where: {
                approvalId,
                actionAt: Not(IsNull())
            },
            order: {
                order: "ASC"
            },
        })
    }

    async getInfoListUserIdOfStepByApprovalId(id: any) {
        const steps = await this.getAllStepByApprovalId(id)
        let pastActionUserId = []
        let lastActionUserId = null
        let nextAction = null
        let nextActionUserId = []
        let nextConsentActionUserId = []
        let requesterId = null
        let allRelevantIds = []

        let stepPosition = Position.Past
        for (const step of steps) {
            allRelevantIds.push(...(step.approveBy ?? []), step.grantFrom)

            if (stepPosition === Position.Future) continue

            if (step.currentStep) stepPosition = Position.Present
            else if (stepPosition === Position.Present) stepPosition = Position.Future

            if (step.action === ApprovalProcessAction.Submit) {
                requesterId = step.createdBy
                pastActionUserId.push(step.createdBy)
                allRelevantIds.push(step.createdBy)
            }

            switch (stepPosition) {
                case Position.Past:
                    pastActionUserId.push(...(step.approveBy ?? []), step.grantFrom)
                    lastActionUserId = step.actionBy
                    break
                case Position.Present:
                    nextActionUserId = !step.actionBy ? step.approveBy : []
                    nextConsentActionUserId = !step.actionBy ? step.consentBy : []
                    nextAction = step.approvalAction
                    break
                case Position.Future:
                    break
            }
        }

        const lastStep = steps?.at(-1)

        if (stepPosition === Position.Past || lastStep.actionAt) {
            nextActionUserId = []
            nextConsentActionUserId = []
        }

        pastActionUserId = await this.officeUserRepo.getAllUserIdsAllWayByIds(arrayConvertToDistinctAndNotNull(pastActionUserId))
        nextActionUserId = await this.officeUserRepo.getAllUserIdsAllWayByIds(arrayConvertToDistinctAndNotNull(nextActionUserId))
        nextConsentActionUserId = await this.officeUserRepo.getAllUserIdsAllWayByIds(arrayConvertToDistinctAndNotNull(nextConsentActionUserId))
        allRelevantIds = await this.officeUserRepo.getAllUserIdsAllWayByIds(arrayConvertToDistinctAndNotNull(allRelevantIds))
        requesterId = (await this.officeUserRepo.getUserAllWayById(requesterId))?.id
        lastActionUserId = (await this.officeUserRepo.getUserAllWayById(lastActionUserId))?.id

        return {
            pastActionUserId,
            lastActionUserId,
            nextAction,
            nextActionUserId,
            nextConsentActionUserId,
            allRelevantIds,
            requesterId,
            lastStepId: lastStep?.id,
            lastStep: lastStep,
        }
    }

    async getAllStepsApprovalByRequester() {
        const requester = await RequestContext.currentUser()

        return this.find({
            where: [
                {
                    action: Not(In([ApprovalProcessAction.Submit, ApprovalProcessAction.Comment, ApprovalProcessAction.Pending])),
                    actionBy: In([requester.id, requester.iamUserId])
                },
                {
                    action: Not(In([ApprovalProcessAction.Submit, ApprovalProcessAction.Comment, ApprovalProcessAction.Pending])),
                    approveBy: ArrayContains([requester.id])
                },
                {
                    action: Not(In([ApprovalProcessAction.Submit, ApprovalProcessAction.Comment, ApprovalProcessAction.Pending])),
                    approveBy: ArrayContains([requester.iamUserId])
                },
                {
                    approvalAction: ApprovalAction.Consent,
                    actionAt: Not(IsNull()),
                    consentBy: ArrayContains([requester.id])
                }
            ],
            order: {
                createdAt: "DESC"
            }
        })
    }

    async getCurrentApprovalStep(id: string) {
        return this.findOne({
            where: {
                approvalId: id,
                approvalAction: ApprovalAction.Approve,
                actionAt: IsNull()
            },
            order: {
                actionAt: "ASC",
                order: "ASC"
            }
        })
    }

    async getCurrentStepByApprovalId(approvalId: string) {
        return this.findOne({
            where: {
                approvalId,
                currentStep: true,
                action: IsNull()
            }
        })
    }

    async getApproveStepByApprovalIdAfterOrder(approvalId: string | any, order: number | any) {
        return this.findOne({
            where: {
                approvalId,
                approvalAction: ApprovalAction.Approve,
                action: IsNull(),
                order: MoreThan(order)
            },
            order: {
                order: 'ASC'
            }
        })
    }

    async getFirstStepInactionByApprovalId(approvalId: string | any) {
        return this.findOne({
            where: {
                approvalId,
                action: IsNull()
            },
            order: {
                order: 'ASC'
            }
        })
    }

    async getFirstStepInactionByApprovalIdBeforeOrder(approvalId: string | any, order: number | any) {
        return this.findOne({
            where: {
                approvalId,
                action: IsNull(),
                order: LessThan(order)
            },
            order: {
                order: 'ASC'
            }
        })
    }

    async getFirstStepConsentInactionByApprovalIdBeforeOrder(approvalId: string | any, order: number | any) {
        return this.findOne({
            where: {
                approvalId,
                action: IsNull(),
                approvalAction: ApprovalAction.Consent,
                order: LessThan(order)
            },
            order: {
                order: 'ASC'
            }
        })
    }

    async getFirstStepInactionByApprovalIdAfterOrder(approvalId: string | any, order: number | any) {
        return this.findOne({
            where: {
                approvalId,
                action: IsNull(),
                order: MoreThan(order)
            },
            order: {
                order: 'ASC'
            }
        })
    }

    async getAllStepActionByApprovalId(approvalId: string | any) {
        return this.createQueryBuilder()
            .where({
                approvalId,
                action: Not(IsNull())
            })
            .getMany()
    }

    async getStepOfApprovalByOrder(approvalId: string | any, order: number) {
        return this.findOne({
            where: {
                approvalId,
                order
            }
        })
    }

    async getSubmitStepOfApproval(approvalId: string | any) {
        return this.findOne({
            where: {
                approvalId,
                action: ApprovalProcessAction.Submit
            }
        })
    }
}