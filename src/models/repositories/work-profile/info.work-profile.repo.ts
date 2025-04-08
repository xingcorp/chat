import { Injectable } from "@nestjs/common";
import { Between, DataSource, IsNull, LessThanOrEqual, MoreThan, Repository } from "typeorm";
import { UserWorkProfileInfo } from "@models/entities";
import { WorkProfileAction, WorkProfileActionType, WorkProfileChangeType } from "@enum/work-profile/work-profile.enum";
import { RequestContext } from "@common/context/request.context";
import { datetimeEndOfLocalDay, datetimeStartOfLocalDay } from "@utils/datetime.utils";

@Injectable()
export class InfoWorkProfileRepo extends Repository<UserWorkProfileInfo> {
    constructor(private dataSource: DataSource) {
        super(UserWorkProfileInfo, dataSource.createEntityManager());
    }

    async getByWorkProfileId(id: string) {
        return this.findOneBy({
            workProfile: {id},
        })
    }

    createNew(args: {
        reason: string;
        decidedNumber: string;
        decidedDate: number;
        activeDate: number;
        endDate?: number;
        type: WorkProfileChangeType;
        isDecided: boolean;
        note?: string;
        attachmentIds?: string[];
    }) {
        const actionType = this.getActionTypeByType(args.type)

        return this.create({
            actionType,
            type: args.type,
            reason: args.reason,
            activeDate: new Date(args.activeDate),
            endDate: args.endDate ? new Date(args.endDate) : null,
            isDecided: args.isDecided,
            decidedNumber: args.isDecided ? args.decidedNumber : null,
            decidedDate: args.isDecided ? new Date(args.decidedDate) : null,
            note: args.note,
            attachmentIds: args.attachmentIds,
            createdBy: RequestContext.currentRequestId() ?? null,
            updatedBy: RequestContext.currentRequestId() ?? null,
        })
    }

    async changeByWorkProfileId(id: string, args: {
        reason?: string;
        decidedNumber?: string;
        decidedDate?: number;
        activeDate?: number;
        endDate?: number;
        type?: WorkProfileChangeType;
        isDecided?: boolean;
        note?: string;
        attachmentIds?: string[];
    }) {
        const info = await this.getByWorkProfileId(id)
        info.type = args.type ?? info.type
        info.reason = args.reason ?? info.reason
        info.activeDate = args.activeDate ? new Date(args.activeDate) : info.activeDate
        info.endDate = args.endDate ? new Date(args.endDate) : info.endDate
        info.isDecided = args.isDecided ?? info.isDecided
        info.decidedNumber = args.decidedNumber ?? info.decidedNumber
        info.decidedDate = args.decidedDate ? new Date(args.decidedDate) : info.decidedDate
        info.note = args.note ?? info.note
        info.attachmentIds = args.attachmentIds ?? info.attachmentIds
        info.updatedBy = RequestContext.currentRequestId() ?? info.updatedBy

        return info
    }

    async getActiveRecordByUserIdAndDate(id: string, date: Date = datetimeEndOfLocalDay()) {
        return this.findOne({
            relations: ['workProfile'],
            where: {
                workProfile: {
                    user: {id}
                },
                activeDate: LessThanOrEqual(date)
            },
            order: {
                activeDate: "DESC"
            }
        })
    }

    async allActiveTodayRecord() {
        const yesterday = datetimeStartOfLocalDay()
        const today = datetimeEndOfLocalDay()

        return this.find({
            relations: ['workProfile'],
            where: {
                activeDate: Between(yesterday, today)
            }
        })
    }

    getActionTypeByType(type: WorkProfileChangeType) {
        let activeType = WorkProfileAction.Update

        activeType = WorkProfileActionType.Create.includes(type) ? WorkProfileAction.Create : activeType
        activeType = WorkProfileActionType.Remove.includes(type) ? WorkProfileAction.Remove : activeType

        return activeType
    }

    listNullActionType() {
        return this.find({
            where: {
                actionType: IsNull()
            }
        })
    }
}