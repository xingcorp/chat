import { Inject, Injectable } from "@nestjs/common";
import {
    Connection,
    DataSource, EntityManager,
    EntitySubscriberInterface,
    InsertEvent,
    ObjectLiteral,
    UpdateEvent
} from "typeorm";
import {
    UserWorkProfile,
    UserWorkProfileDetail,
    UserWorkProfileInfo,
} from "@models/entities";
import { InjectConnection, InjectRepository } from "@nestjs/typeorm";
import {
    DetailWorkProfileRepo,
    InfoWorkProfileRepo,
    OfficeUserRepo,
    UserDepartmentRepo,
    WorkProfileRepo
} from "@models/repositories";
import { WorkProfileService } from "@modules/graphql/management/work-profile/work-profile.service";
import { WorkProfileActionKind } from "@enum/work-profile/work-profile.enum";
import { datetimeEndOfLocalDay } from "@utils/datetime.utils";

@Injectable()
// @EventSubscriber()
export class DetailWorkProfileSubscriber implements EntitySubscriberInterface<UserWorkProfileDetail> {
    private entity: ObjectLiteral;
    private workProfile: UserWorkProfile;
    private manager: EntityManager;
    private workProfileInfo: UserWorkProfileInfo;
    private workProfileDetail: ObjectLiteral;
    private updateEvent: UpdateEvent<UserWorkProfileDetail>;

    constructor(
        @InjectConnection() readonly connection: Connection,
        private dataSource: DataSource,
        @InjectRepository(DetailWorkProfileRepo)
        private detailWorkProfileRepo: DetailWorkProfileRepo,
        @InjectRepository(InfoWorkProfileRepo)
        private infoWorkProfileRepo: InfoWorkProfileRepo,
        @InjectRepository(WorkProfileRepo)
        private workProfileRepo: WorkProfileRepo,
        @InjectRepository(OfficeUserRepo)
        private officeUserRepo: OfficeUserRepo,
        @InjectRepository(UserDepartmentRepo)
        private userDepartmentRepo: UserDepartmentRepo,
        @Inject(WorkProfileService)
        private readonly workProfileService: WorkProfileService,
    ) {
        connection.subscribers.push(this);
    }

    /**
     * Indicates that this subscriber only listen to OfficeUser events.
     */
    listenTo() {
        return UserWorkProfileDetail
    }

    /**
     * Called after entity insertion.
     */
    async beforeInsert(event: InsertEvent<UserWorkProfileDetail>) {
        try {
            this.entity = event.entity;
            this.manager = event.manager;

            await this.checkToUpdateUserProfileNew()

        } catch (e) {
            console.log('UserWorkProfileDetail:afterInsert:error', e)
        }
    }

    /**
     * Called before entity update.
     */
    async beforeUpdate(event: UpdateEvent<UserWorkProfileDetail>) {
        try {
            this.entity = event.entity;
            this.manager = event.manager;

            const fieldsChange = [...new Set([
                ...event.updatedColumns.map(i => i.propertyName),
                ...event.updatedRelations.map(i => i.propertyName)
            ])]

            if (fieldsChange.includes('code')) return

            await this.checkToUpdateUserProfileNew(WorkProfileActionKind.Update)

        } catch (e) {
            console.log('UserWorkProfileDetail:afterUpdate:error', e)
        }
    }

    private async checkToUpdateUserProfileNew(action: WorkProfileActionKind = WorkProfileActionKind.Create) {
        this.workProfileDetail = this.entity

        this.workProfile = await this.workProfileRepo.findOneBy({id: this.entity.workProfile.id})
        const user = await this.officeUserRepo.getById(this.workProfile.user.id)
        console.log('checkToUpdateUserProfile 1111', this.workProfileDetail, this.entity)
        /*not run when create user*/
        if (!user) return

        this.workProfileInfo = await this.infoWorkProfileRepo.findOneBy({workProfile: {id: this.workProfile.id}})
        const oldActiveInfo = await this.infoWorkProfileRepo.getActiveRecordByUserIdAndDate(this.workProfile.user.id)

        console.log('checkToUpdateUserProfile 2222', oldActiveInfo, this.workProfileInfo)
        if (
            /*run when create first record for exist user*/
            !oldActiveInfo
            || (oldActiveInfo.id === this.workProfileInfo.id)
            /*run when upsert record is active record*/
            || (oldActiveInfo.activeDate <= this.workProfileInfo.activeDate && this.workProfileInfo.activeDate <= datetimeEndOfLocalDay())
        ) {
            await this.workProfileService.updateUserWorkProfileData(this.workProfile.user.id, this.entity, this.manager, action)

            console.log('checkToUpdateUserProfile 333', this.entity)
        }
    }
}