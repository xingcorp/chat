import { forwardRef, Inject, SetMetadata, UseInterceptors } from "@nestjs/common"
import { Args, Mutation, Query, Resolver } from "@nestjs/graphql"
import {
    ApprovalForm,
    ApprovalStep,
    OfficeApproval, OfficeFilter,
    OfficeUser,
} from "src/models/entities"
import { ServiceActions, ServiceKeys, UserType } from "src/modules/core/middleware/guard/service.action"
import {
    ApprovalActionArgs, ApprovalApproveStepUpdateInput,
    ApprovalArgs, ApprovalCommentCreate,
    ApprovalFilter, ApprovalFilterCreateInput, ApprovalFilterListFilter, ApprovalFilterUpdateInput,
    ApprovalFormArgs,
    ApprovalFormFilter, ApprovalSubscriberUpdateInput, ApprovalUpdateInput,
    EditApprovalFormArgs,
    ShoppingRequestArgs
} from "./approval.args"
import { OfficeError } from "src/common/office.error"
import { RandomHelper } from "src/common/random"
import {
    ApprovalFilterListResponse,
    ApprovalFormResponse,
    ApprovalMenuResponse,
    ApprovalResponse
} from "./approval.response"
import {
    OfficeRequester,
    OfficeRequesterId,
    OfficeUserType,
    RequesterId
} from "src/modules/core/middleware/decorator/user.decorator"
import { ApprovalSource } from "src/models/entities/approval"
import { BearerAccessToken } from "src/modules/core/middleware/decorator/request.decorator"
import { ApprovalService } from "./approval.service"
import { OfficeShoppingRequest } from "src/models/entities/office.shopping.request"
import { ErrorInterceptor } from "@interceptors/error.interceptor";
import {
    FixedDataOrgChartUserAllAndWChildInterceptor, FixedDataOrgChartUserAllAndWithChildInterceptor,
    FixedDataOrgChartUserAllInterceptor
} from "@interceptors/org-chart.interceptor";
import { ApprovalSubmitTypeEnum } from "@enum/approval/approval/approval.enum";

@Resolver()
export class ApprovalResolver {
    constructor(
        @Inject(forwardRef(() => ApprovalService))
        private readonly approvalService: ApprovalService,
    ) { }

    @Mutation(() => ApprovalForm, { name: 'officeApprovalAddForm' })
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    @SetMetadata(ServiceKeys.UserType, [UserType.SYSTEM_USER])
    @UseInterceptors(ErrorInterceptor)
    @UseInterceptors(FixedDataOrgChartUserAllAndWChildInterceptor)
    async addApprovalForm(
        @Args('arguments', { nullable: false }) args: ApprovalFormArgs,
        @BearerAccessToken() token: string,
        @RequesterId() requesterId: string,
    ): Promise<ApprovalForm> {
        return this.approvalService.addApprovalForm(args, token, requesterId)
    }

    @Mutation(() => ApprovalForm, { name: 'officeApprovalEditForm' })
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    @SetMetadata(ServiceKeys.UserType, [UserType.SYSTEM_USER])
    @UseInterceptors(ErrorInterceptor)
    @UseInterceptors(FixedDataOrgChartUserAllAndWChildInterceptor)
    async officeApprovalEditForm(
        @Args('arguments', { nullable: false }) args: EditApprovalFormArgs,
        @BearerAccessToken() token: string,
        @RequesterId() requesterId: string,
    ): Promise<ApprovalForm> {
        return this.approvalService.officeApprovalEditForm(args, token, requesterId)
    }

    @Mutation(() => ApprovalForm, { name: 'managerApprovalOnOff' })
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    @SetMetadata(ServiceKeys.UserType, [UserType.SYSTEM_USER])
    @UseInterceptors(FixedDataOrgChartUserAllAndWChildInterceptor)
    async managerApprovalOnOff(
        @Args("id", { nullable: false }) id: string,
    ): Promise<ApprovalForm> {
        return this.approvalService.onOff(id)
    }

    @Query(_return => ApprovalForm, { name: "officeApprovalGetForm" })
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    async getApprovalForm(
        @Args("id") id: string,
    ): Promise<ApprovalForm> {
        const form = await ApprovalForm.findOne({
            relations: ['users'],
            where: { id: id }
        })

        if (!form) throw OfficeError.ApprovalFormNotFound

        return form
    }

    @Query(_return => ApprovalFormResponse, { name: "officeApprovalFormGetList" })
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    @UseInterceptors(FixedDataOrgChartUserAllAndWChildInterceptor)
    async getApprovalFormList(
        @Args("filter", { nullable: true }) filter: ApprovalFormFilter,
        @OfficeUserType() userType: string,
        @RequesterId() requesterId: string,
    ): Promise<ApprovalFormResponse> {

        const [approvalForms, total] = await this.approvalService.getApprovalFormList(filter, userType, requesterId)

        return {
            total,
            count: approvalForms.length,
            approvalForms
        }
    }

    //Pending
    @Mutation(() => OfficeApproval, { name: 'officeRequestApproval' })
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    @SetMetadata(ServiceKeys.UserType, [UserType.NORMAL_USER])
    @UseInterceptors(ErrorInterceptor)
    async requestApproval(
        @Args('arguments', { nullable: false }) args: ApprovalArgs,
    ): Promise<OfficeApproval> {
        return this.approvalService.submitApproval(args)
    }

    @Mutation(() => OfficeApproval, { name: 'officeApprovalSubscriberUpdate' })
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    @SetMetadata(ServiceKeys.UserType, [UserType.NORMAL_USER])
    @UseInterceptors(ErrorInterceptor)
    @UseInterceptors(FixedDataOrgChartUserAllAndWithChildInterceptor)
    async officeApprovalSubscriberUpdate(
        @Args('arguments', { nullable: false }) args: ApprovalSubscriberUpdateInput,
    ): Promise<OfficeApproval> {
        return this.approvalService.updateSubscriber(args)
    }

    @Mutation(() => OfficeApproval, { name: 'officeApprovalApproveStepUpdate' })
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    @SetMetadata(ServiceKeys.UserType, [UserType.NORMAL_USER])
    @UseInterceptors(ErrorInterceptor)
    @UseInterceptors(FixedDataOrgChartUserAllAndWithChildInterceptor)
    async officeApprovalApproveStepUpdate(
        @Args('arguments', { nullable: false }) args: ApprovalApproveStepUpdateInput,
    ): Promise<OfficeApproval> {
        return this.approvalService.updateApproveStep(args)
    }

    @Mutation(() => OfficeApproval, { name: 'officeApprovalUpdate' })
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    @SetMetadata(ServiceKeys.UserType, [UserType.NORMAL_USER])
    @UseInterceptors(ErrorInterceptor)
    @UseInterceptors(FixedDataOrgChartUserAllAndWithChildInterceptor)
    async officeApprovalUpdate(
        @Args('arguments', { nullable: false }) args: ApprovalUpdateInput,
    ): Promise<OfficeApproval> {
        return this.approvalService.update(args)
    }

    @Mutation(() => OfficeApproval, { name: 'officeApprovalRemove' })
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    @SetMetadata(ServiceKeys.UserType, [UserType.NORMAL_USER])
    @UseInterceptors(ErrorInterceptor)
    @UseInterceptors(FixedDataOrgChartUserAllAndWithChildInterceptor)
    async officeApprovalRemove(
        @Args("id") id: string,
    ): Promise<OfficeApproval> {
        return this.approvalService.remove(id)
    }

    @Mutation(() => OfficeShoppingRequest, { name: 'officeShoppingRequest' })
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    @SetMetadata(ServiceKeys.UserType, [UserType.NORMAL_USER])
    async shoppingRequest(
        @Args('arguments', { nullable: false }) args: ShoppingRequestArgs,
        @BearerAccessToken() token: string,
        @RequesterId() requesterId: string,
        @OfficeRequesterId() officeId: string,
    ): Promise<OfficeShoppingRequest> {
        const shoppingRequest = OfficeShoppingRequest.create({
            id: RandomHelper.generateUUID(),
            name: args.name,
            expectedCost: args.expectedCost,
            note: args.note,
            createdBy: officeId,
            updatedBy: officeId
        })

        //tạo luồng phê duyệt & gắn approvalId
        const approval = await this.approvalService.submitApproval({
            source: ApprovalSource.Template,
            name: shoppingRequest.name,
            note: shoppingRequest.note,
            formId: args.formId,
            formFieldData: args.formFieldData,
            structure: null,
            imageIds: args.imageIds,
            attachmentIds: args.attachmentIds,
            submitType: ApprovalSubmitTypeEnum.Submit,
            subscriberIds: args.subscriberIds
        }, shoppingRequest.id)
        shoppingRequest.approvalId = approval.id

        return shoppingRequest.save()
    }

    @Mutation(() => ApprovalStep, { name: 'officeUpdateApprovalAction' })
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    @SetMetadata(ServiceKeys.UserType, [UserType.NORMAL_USER])
    async updateApprovalAction(
        @Args('arguments', { nullable: false }) args: ApprovalActionArgs,
        @BearerAccessToken() token: string,
    ): Promise<ApprovalStep> {
        return this.approvalService.updateApprovalAction(args)
    }

    @Query(_return => OfficeApproval, { name: "officeGetApproval" })
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    @UseInterceptors(FixedDataOrgChartUserAllInterceptor)
    async getApproval(
        @Args("id") id: string,
    ): Promise<OfficeApproval> {
        return this.approvalService.approvalGet(id)
    }

    @Query(_return => OfficeApproval, { name: "officeGetApprovalPublic" })
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    @SetMetadata(ServiceKeys.UserType, [UserType.NORMAL_USER])
    @UseInterceptors(FixedDataOrgChartUserAllInterceptor)
    async getApprovalPublic(
        @Args("id") id: string,
    ): Promise<OfficeApproval> {
        return this.approvalService.approvalGetPublic(id)
    }

    @Query(() => ApprovalResponse, { name: "officeGetApprovalList" })
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    @SetMetadata(ServiceKeys.UserType, [UserType.NORMAL_USER])
    async getApprovalList(
        @Args("filter", { nullable: true }) filter: ApprovalFilter,
        @OfficeRequester() officeRequester: OfficeUser,
    ): Promise<ApprovalResponse> {
        return this.approvalService.getApprovalList(filter, officeRequester)
    }

    @Query(() => ApprovalMenuResponse, { name: "officeApprovalMenuCount" })
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    @SetMetadata(ServiceKeys.UserType, [UserType.NORMAL_USER])
    @UseInterceptors(FixedDataOrgChartUserAllAndWChildInterceptor)
    async officeApprovalMenuCount(): Promise<ApprovalMenuResponse> {
        return this.approvalService.approvalMenuList()
    }

    @Mutation(() => OfficeFilter, { name: 'officeApprovalFilterCreate' })
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    @SetMetadata(ServiceKeys.UserType, [UserType.NORMAL_USER])
    @UseInterceptors(ErrorInterceptor)
    @UseInterceptors(FixedDataOrgChartUserAllAndWChildInterceptor)
    async officeApprovalFilterCreate(
        @Args("args", { nullable: true }) args: ApprovalFilterCreateInput,
    ): Promise<OfficeFilter> {
        return this.approvalService.approvalFilterCreate(args)
    }

    @Mutation(() => OfficeFilter, { name: 'officeApprovalFilterUpdate' })
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    @SetMetadata(ServiceKeys.UserType, [UserType.NORMAL_USER])
    @UseInterceptors(ErrorInterceptor)
    @UseInterceptors(FixedDataOrgChartUserAllAndWChildInterceptor)
    async officeApprovalFilterUpdate(
        @Args("args", { nullable: true }) args: ApprovalFilterUpdateInput,
    ): Promise<OfficeFilter> {
        return this.approvalService.approvalFilterUpdate(args)
    }

    @Mutation(() => OfficeFilter, { name: 'officeApprovalFilterRemove' })
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    @SetMetadata(ServiceKeys.UserType, [UserType.NORMAL_USER])
    @UseInterceptors(ErrorInterceptor)
    @UseInterceptors(FixedDataOrgChartUserAllAndWChildInterceptor)
    async officeApprovalFilterRemove(
        @Args("id", { nullable: true }) id: string,
    ): Promise<OfficeFilter> {
        return this.approvalService.approvalFilterRemove(id)
    }

    @Query(() => OfficeFilter, { name: "officeApprovalFilterGet" })
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    @SetMetadata(ServiceKeys.UserType, [UserType.NORMAL_USER])
    @UseInterceptors(FixedDataOrgChartUserAllAndWChildInterceptor)
    async officeApprovalFilterGet(
        @Args("id", { nullable: true }) id: string,
    ): Promise<OfficeFilter> {
        return this.approvalService.approvalFilterGet(id)
    }

    @Query(() => ApprovalFilterListResponse, { name: "officeApprovalFilterList" })
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    @SetMetadata(ServiceKeys.UserType, [UserType.NORMAL_USER])
    @UseInterceptors(FixedDataOrgChartUserAllAndWChildInterceptor)
    async officeApprovalFilterList(
        @Args("filter", { nullable: true }) filter: ApprovalFilterListFilter,
    ): Promise<ApprovalFilterListResponse> {
        return this.approvalService.approvalFilterList(filter)
    }

    @Mutation(() => OfficeApproval, { name: 'officeApprovalCommentCreate', nullable: true })
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    @SetMetadata(ServiceKeys.UserType, [UserType.NORMAL_USER])
    @UseInterceptors(FixedDataOrgChartUserAllInterceptor)
    @UseInterceptors(ErrorInterceptor)
    async officeApprovalCommentCreate(
        @Args('arguments', { nullable: false }) args: ApprovalCommentCreate,
    ): Promise<OfficeApproval> {
        return this.approvalService.commentCreate(args)
    }
}