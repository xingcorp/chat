import { Injectable } from "@nestjs/common";
import { DataSource, Repository } from "typeorm";
import { NotificationCampaign } from "@models/entities/notification.campaign";
import { NotificationCampaignKind } from "@enum/campaign/campaign.enum";

@Injectable()
export class NotificationCampaignRepo extends Repository<NotificationCampaign> {
    constructor(private dataSource: DataSource) {
        super(NotificationCampaign, dataSource.createEntityManager());
    }

    async getBookingRoomById(id: string, withDeleted: boolean = false) {
        return this.findOne({
            where: {
                notifyType: NotificationCampaignKind.Book_Room,
                notifyTypeId: id
            },
            withDeleted
        })
    }

    async getBookingCarById(id: string, withDeleted: boolean = false) {
        return this.findOne({
            where: {
                notifyType: NotificationCampaignKind.Book_Car,
                notifyTypeId: id
            },
            withDeleted
        })
    }
}