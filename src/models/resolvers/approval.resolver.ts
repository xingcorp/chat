import { Parent, ResolveField, Resolver } from "@nestjs/graphql"
import {
    ApprovalField, ApprovalForm, ApprovalForward,
    ApprovalStep,
    BookingMeetingRoom, DocumentWiki,
    OfficeApproval,
    OfficeLogs,
    OfficeUser, VersionWiki
} from "../entities"
import { ArrayContains, Between, ILike, In, IsNull, MoreThan, Not } from "typeorm"
import { ApprovalAction, ApprovalType } from "../entities/approval.form"
import { OfficeRequester } from "src/modules/core/middleware/decorator/user.decorator"
import { ApprovalStatus } from "../entities/approval"
import { CarBookingRequest } from "../entities/car.booking.request"
import { OfficeShoppingRequest } from "../entities/office.shopping.request"
import { OfficeFeatureLogType, OfficeLogType } from "@enum/logs/logs.enum";
import { RequestContext } from "@common/context/request.context";
import { File } from "@core/storage/objects/file";
import { forwardRef, Inject } from "@nestjs/common";
import { StorageService } from "@core/storage/storage.service";
import { InjectRepository } from "@nestjs/typeorm";
import { OfficeApprovalRepo } from "@models/repositories";

@Resolver(_of => OfficeApproval)
export class OfficeApprovalFieldResolver {
    constructor(
        @Inject(forwardRef(() => StorageService))
        private readonly storageService: StorageService,
        @InjectRepository(OfficeApprovalRepo)
        private approvalRepo: OfficeApprovalRepo,
    ) { }

    @ResolveField('subcribers', _return => [OfficeUser], { nullable: true })
    async subcribers(
        @Parent() root: OfficeApproval
    ) {
        if (root.subscriberIds) {
            return OfficeUser.find({
                where: {
                    id: In(root.subscriberIds)
                }
            })
        }

        return null
    }

    @ResolveField('fields', _return => [ApprovalField], { nullable: true })
    async fields(
        @Parent() root: OfficeApproval
    ) {
        return ApprovalField.find({
            where: {
                approvalId: root.id
            },
            order: {
                order: "ASC"
            }
        })

        // return result.filter(r => !(r.dataType === DataType.Date && !r.dateValue))
    }

    @ResolveField('steps', _return => [ApprovalStep], { nullable: true })
    async steps(
        @Parent() root: OfficeApproval
    ) {
        return ApprovalStep.find({
            where: {
                approvalId: root.id
            },
            order: {
                actionAt: "ASC",
                order: "ASC"
            }
        })
    }

    @ResolveField('yourAction', _return => ApprovalAction, { nullable: true })
    async yourAction(
        @Parent() root: OfficeApproval,
    ) {
        const requesterId = await RequestContext.currentId()
        if (root.status === ApprovalStatus.UnderReview || root.status === ApprovalStatus.Pending) {
            const consent = await ApprovalStep.findOne({
                where: {
                    approvalId: root.id,
                    canAction: true,
                    consentBy: ArrayContains([requesterId]),
                    actionAt: IsNull()
                }
            })

            if (consent) return ApprovalAction.Consent

            const approval = await ApprovalStep.findOne({
                where: {
                    currentStep: true,
                    approveBy: ArrayContains([requesterId]),
                    actionAt: IsNull(),
                    approvalId: root.id,
                }
            })
            
            if (approval) return ApprovalAction.Approve
        }
        
        return null
    }

    @ResolveField('requester', _return => OfficeUser, { nullable: true })
    async requester(
        @Parent() root: OfficeApproval
    ) {
        if (root.createdBy) {
            return OfficeUser.findOne({
                where: [
                    { id: root.createdBy },
                    { iamUserId: root.createdBy },
                    { iamUserUsedIds: ILike(`%${root.createdBy}%`) },
                ]
            })
        }

        return null
    }

    @ResolveField('carBookingRequest', _return => CarBookingRequest, { nullable: true })
    async carBookingRequest(
        @Parent() root: OfficeApproval
    ) {
        if (root.requestId && root.type === ApprovalType.CarBooking) {
            return CarBookingRequest.findOne({
                where: {
                    id: root.requestId
                },
                withDeleted: true
            })
        }

        return null
    }

    @ResolveField('roomBookingRequest', _return => BookingMeetingRoom, { nullable: true })
    async roomBookingRequest(
        @Parent() root: OfficeApproval
    ) {
        if (root.requestId && root.type === ApprovalType.RoomBooking) {
            return BookingMeetingRoom.findOne({
                relations: ['participants', 'meetingRoom'],
                where: {
                    id: root.requestId
                },
                withDeleted: true
            })
        }

        return null
    }

    @ResolveField('shoppingRequest', _return => OfficeShoppingRequest, { nullable: true })
    async shoppingRequest(
        @Parent() root: OfficeApproval
    ) {
        if (root.requestId && root.type === ApprovalType.OfficeShopping) {
            return OfficeShoppingRequest.findOne({
                where: {
                    id: root.requestId
                }
            })
        }

        return null
    }

    @ResolveField('comments', _return => [OfficeLogs], { nullable: true })
    comments(
        @Parent() root: OfficeApproval
    ){
        return OfficeLogs.find({
            where: {
                featureLogType: OfficeFeatureLogType.Approval,
                featureLogId: root.id,
                type: OfficeLogType.Comment,
            },
            order: {
                createdAt: 'ASC'
            }
        })
    }

    @ResolveField('history', _return => [OfficeLogs], { nullable: true })
    history(
        @Parent() root: OfficeApproval
    ){
        return OfficeLogs.find({
            where: {
                featureLogType: OfficeFeatureLogType.Approval,
                featureLogId: root.id,
                type: OfficeLogType.History,
            },
            order: {
                createdAt: 'ASC'
            }
        })
    }

    @ResolveField('isRead', _return => Boolean, { nullable: true })
    async isRead(
        @Parent() root: OfficeApproval
    ){
        return !!(await OfficeUser.findOne({
            relations: ['approvalsRead'],
            where: {
                id: await RequestContext.currentId(),
                approvalsRead: {
                    id: root.id
                }
            }
        }))
    }

    @ResolveField('attachments', _return => [File], {nullable: true})
    async attachments(
        @Parent() root: OfficeApproval
    ) {
        if (!root.attachmentIds || !root.attachmentIds?.length) return null

        const {data} = await this.storageService.getFilesDetail(RequestContext.currentToken(), root.attachmentIds)

        return data?.files
    }

    @ResolveField('images', _return => [File], {nullable: true})
    async images(
        @Parent() root: OfficeApproval
    ) {
        if (!root.imageIds || !root.imageIds?.length) return null

        const {data} = await this.storageService.getFilesDetail(RequestContext.currentToken(), root.imageIds)

        return data?.files
    }

    @ResolveField('subscribersDefault', _return => [OfficeUser], { nullable: true })
    async subscribersDefault(
        @Parent() root: OfficeApproval
    ) {
        if (root.formId) {
            const form = await ApprovalForm.findOneBy({id: root.formId})

            if (!form) return null

            return OfficeUser.find({
                where: {
                    id: In(form?.subscriberIds ?? [])
                }
            })
        }

        return null
    }

    @ResolveField('forward', _return => ApprovalForward, {nullable: true})
    async forward(
        @Parent() root: OfficeApproval
    ) {
        const _this = await OfficeApproval.findOne({
            relations: ['forward'],
            where: {
                id: root.id
            }
        })

        return _this.forward
    }

    @ResolveField('wiki', _return => DocumentWiki, {nullable: true})
    async wiki(
        @Parent() root: OfficeApproval
    ) {
        if (root.type !== ApprovalType.WikiRelease || !root.relationId) return null

        const version = await VersionWiki.createQueryBuilder('qb')
            .leftJoinAndSelect('qb.wiki', 'wiki')
            .where({id: root.relationId})
            .getOne()

        return version.wiki
    }

    @ResolveField('versionWikiApproval', _return => VersionWiki, {nullable: true})
    async versionWikiApproval(
        @Parent() root: OfficeApproval
    ) {
        let _origin = root
        if (root.status === ApprovalStatus.Forward) {
            _origin = await this.getOriginApprovalForForward(root)
        }

        if (!_origin || _origin.type !== ApprovalType.WikiRelease || !_origin.relationId) return null

        return VersionWiki.createQueryBuilder()
            .where({id: _origin.relationId})
            .getOne()
    }

    private async getOriginApprovalForForward(root: OfficeApproval) {
        const forward = await ApprovalForward.findOne({
            relations: ['originApproval'],
            where: {
                approval: {id: root.id}
            }
        })

        if (!forward) return null

        return this.approvalRepo.findOne({
            where: {id: forward?.originApproval?.id}
        })
    }
}