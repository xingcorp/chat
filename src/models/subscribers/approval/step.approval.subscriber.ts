import { Injectable } from "@nestjs/common";
import { Connection, EntitySubscriberInterface, InsertEvent, ObjectLiteral, UpdateEvent } from "typeorm";
import { ApprovalStep, OfficeApproval } from "@models/entities";
import { InjectConnection } from "@nestjs/typeorm";
import { ApprovalStepRepo, OfficeApprovalRepo } from "@models/repositories";
import { ApprovalAction } from "@models/entities/approval.form";

@Injectable()
// @EventSubscriber()
export class StepApprovalSubscriber implements EntitySubscriberInterface<ApprovalStep> {
    private entity: ObjectLiteral | ApprovalStep;
    private approval: OfficeApproval;
    private event: UpdateEvent<ApprovalStep>;
    private fieldsChange: string[];
    constructor(
        @InjectConnection() readonly connection: Connection,
        private readonly approvalRepo: OfficeApprovalRepo,
        private readonly stepRepo: ApprovalStepRepo,
    ) {
        connection.subscribers.push(this);
    }

    /**
     * Indicates that this subscriber only listen to OfficeUser events.
     */
    listenTo() {
        return ApprovalStep
    }

    private async setDataChange() {
        this.fieldsChange = [
            ...this.event.updatedColumns.map(i => i.propertyName),
            ...this.event.updatedRelations.map(i => i.propertyName)
        ]
    }

    /**
     * Called before entity insertion.
     */
    async beforeInsert(event: InsertEvent<ApprovalStep>) {
        try {
            this.entity = event.entity

            await this.checkToUpdateCurrentStep()

        } catch (e) {
            console.log('beforeInsert ApprovalStep err', e)
        }
    }

    /**
     * Called after entity insertion.
     */
    async afterInsert(event: InsertEvent<ApprovalStep>) {
        try {
            this.entity = event.entity

            this.approval = await this.approvalRepo.findOneBy({id: this.entity.approvalId})

            if (!this.approval) return

            await this.approvalStepOrderUpdate()

        } catch (e) {
            console.log('afterInsert StepApprovalSubscriber err', e)
        }
    }

    /**
     * Called before entity update.
     */
    async beforeUpdate(event: UpdateEvent<ApprovalStep>) {
        try {
            this.event = event
            this.entity = event.entity

            await this.setDataChange()

            await this.checkToSetNewCurrentAndCanActionStep()

        } catch (e) {
            console.log('beforeUpdate ApprovalStep err', e)
        }
    }

    /**
     * Called after entity update.
     */
    async afterUpdate(event: UpdateEvent<ApprovalStep>) {
        try {
            this.entity = event.entity

            await this.approvalStepCanActionUpdate()
        } catch (e) {
            console.log('afterUpdate StepApprovalSubscriber err', e)
        }
    }

    private async approvalStepOrderUpdate() {
        if (!this.entity.order) return

        const afterSteps = await this.stepRepo.getAllInactionStepByApprovalId(this.entity.approvalId)

        if (!afterSteps.length) return

        if (afterSteps[0].order === this.entity.order) {
            for (const step of afterSteps) {
                step.order += 1

                await step.save()
            }
        }
    }

    private async checkToUpdateCurrentStep() {
        if (
            this.entity.approvalAction !== ApprovalAction.Approve
            || this.entity.action
        ) return

        const stepCurrent = await this.stepRepo.getCurrentStepByApprovalId(this.entity.approvalId)

        if (stepCurrent) return

        this.entity.currentStep = true
        this.entity.canAction = true

        await this.approvalStepCanActionUpdate()
    }

    private async approvalStepCanActionUpdate() {
        if (!this.entity.currentStep) return

        const firstInactionStep = await this.stepRepo.getFirstStepInactionByApprovalId(this.entity.approvalId)

        if (!firstInactionStep) return

        if (firstInactionStep.approvalAction === ApprovalAction.Consent && !firstInactionStep.canAction) {
            firstInactionStep.canAction = true
            await firstInactionStep.save()
        }
    }

    private async checkToSetNewCurrentStep() {
        const newCurrentStep = await this.stepRepo.getApproveStepByApprovalIdAfterOrder(this.entity.approvalId, this.entity.order)

        if (newCurrentStep) {
            newCurrentStep.currentStep = true
            newCurrentStep.canAction = true

            await newCurrentStep.save()
        }
    }
    private async checkToSetNewCanActionStepAfterApproval() {
        const newCanAction = await this.stepRepo.getFirstStepConsentInactionByApprovalIdBeforeOrder(this.entity.approvalId, this.entity.order)

        if (newCanAction && !newCanAction.canAction && newCanAction.approvalAction === ApprovalAction.Consent) {
            newCanAction.canAction = true

            await newCanAction.save()
        }
    }

    private async checkToSetNewCanActionStepAfterConsent() {
        const newCanAction = await this.stepRepo.getStepOfApprovalByOrder(this.entity.approvalId, this.entity.order + 1)

        console.log('checkToSetNewCanActionStepAfterConsent', newCanAction?.id)

        if (newCanAction && !newCanAction.canAction && newCanAction.approvalAction === ApprovalAction.Consent) {
            newCanAction.canAction = true

            await newCanAction.save()
        }
    }

    private async checkToSetNewCurrentAndCanActionStep() {
        if (this.entity.approvalAction === ApprovalAction.Approve) {
            if (!this.fieldsChange.includes('currentStep') || this.entity.currentStep) return

            await this.checkToSetNewCurrentStep()
            await this.checkToSetNewCanActionStepAfterApproval()
        }

        if (this.entity.approvalAction === ApprovalAction.Consent) {
            if (!this.fieldsChange.includes('canAction') || this.entity.canAction) return

            await this.checkToSetNewCanActionStepAfterConsent()
        }
    }
}