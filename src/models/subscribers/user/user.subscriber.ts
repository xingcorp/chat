import { forwardRef, Inject, Injectable } from "@nestjs/common";
import { Connection, EntityManager, EntitySubscriberInterface, InsertEvent, ObjectLiteral, UpdateEvent } from "typeorm";
import { OfficeApproval, OfficeUser } from "@models/entities";
import { InjectConnection, InjectRepository } from "@nestjs/typeorm";
import { WorkProfileService } from "@modules/graphql/management/work-profile/work-profile.service";
import { WorkProfileCreateInput } from "@modules/graphql/management/work-profile/dto/work-profile.args";
import { UserDepartmentRepo } from "@models/repositories";
import { StorageService } from "@core/storage/storage.service";
import { WorkProfileChangeType } from "@enum/work-profile/work-profile.enum";
import { getTimeLocal } from "@utils/datetime.utils";
import { RedisService } from "@core/common/redis.service";
import { CACHE_KEY } from "@common/cache-key.common";
import { ObjectStatus } from "@models/entities/profile.info.block";
import { IdentityService } from "@core/iam/identity/identity.service";
import { RedisKey } from "@core/common/common.type";

@Injectable()
// @EventSubscriber()
export class UserSubscriber implements EntitySubscriberInterface<OfficeUser> {
    private entity: OfficeUser;
    private manager: EntityManager;
    private entityUpdate: ObjectLiteral;
    private fieldsChange: string[];

    constructor(
        @InjectConnection() readonly connection: Connection,
        @Inject(IdentityService)
        private readonly identityService: IdentityService,
        @Inject(WorkProfileService)
        private readonly workProfileService: WorkProfileService,
        @InjectRepository(UserDepartmentRepo)
        private readonly userDepartmentRepo: UserDepartmentRepo,
        @Inject(forwardRef(() => StorageService))
        private readonly storageService: StorageService,
        @Inject(forwardRef(() => RedisService))
        private readonly redisService: RedisService
    ) {
        connection.subscribers.push(this);
    }

    /**
     * Indicates that this subscriber only listen to OfficeUser events.
     */
    listenTo() {
        return OfficeUser
    }

    /**
     * Called after entity insertion.
     */
    async afterInsert(event: InsertEvent<OfficeUser>) {
        try {
            this.entity = event.entity
            this.manager = event.manager
            await this.initWorkProfileRecord()
        } catch (e) {
            console.log('UserSubscriber:afterInsert:error', e)
        }
    }

    async afterUpdate(event: UpdateEvent<OfficeUser>) {
        try {
            this.entityUpdate = event.entity

            this.fieldsChange = [...new Set([
                ...event.updatedColumns.map(i => i.propertyName),
                ...event.updatedRelations.map(i => i.propertyName)
            ])]

            if (['fullname', 'status'].some(i => this.fieldsChange.includes(i))) {
                const cacheKey = CACHE_KEY.USER.IDENTITY_PROFILE + '__' + event.entity.id
                await this.redisService.delete(cacheKey)
            }

            await this.checkInactiveUser()
            await this.redisService.delete(RedisKey.UserPublicProfile(this.entityUpdate.id))
            await this.redisService.setWithTtl(RedisKey.UserPublicProfile(this.entityUpdate.id), JSON.stringify(this.entityUpdate), 15 * 60)
        } catch (e) {
            console.log('UserSubscriber:afterInsert:error', e)
        }
    }

    private async initWorkProfileRecord() {
        const department = await this.userDepartmentRepo.getByUserId(this.entity.id)

        const args: WorkProfileCreateInput = {
            activeDate: getTimeLocal(this.entity.onboardingOn),
            endDate: null,
            decidedDate: null,
            decidedNumber: null,
            departmentId: department.departmentId,
            isDecided: false,
            leaderId: this.entity.leaderId,
            major: this.entity.major,
            metadata: this.entity.metadata[0] !== null ? JSON.parse(this.entity.metadata[0]) : null,
            reason: null,
            titleId: department.titleId,
            type: WorkProfileChangeType.NewRecruitment,
            userCode: this.entity.code,
            user: this.entity,
            userId: this.entity.id,
            note: null,
            attachmentIds: null,
        }

        return this.workProfileService.create(args, this.manager)
    }

    private async checkInactiveUser() {
        if (this.fieldsChange.includes('status') && this.entityUpdate.status === ObjectStatus.Inactive) {

            await this.removeCacheIdentify(this.entityUpdate.id)
            return this.identityService.deleteSessionTokenUserInActive(this.entityUpdate?.iamUserId)
        }
    }

    private async removeCacheIdentify(id: any) {
        const cacheKey = CACHE_KEY.USER.IDENTITY_PROFILE + '__' + id
        const cacheKeyId = CACHE_KEY.USER.IDENTITY_PROFILE + '__' + id + '__' + 'id'
        const cacheKeyName = CACHE_KEY.USER.IDENTITY_PROFILE + '__' + id + '__' + 'name'
        const cacheKeyStatus = CACHE_KEY.USER.IDENTITY_PROFILE + '__' + id + '__' + 'status'

        await this.redisService.delete(cacheKey)
        await this.redisService.delete(cacheKeyId)
        await this.redisService.delete(cacheKeyName)
        await this.redisService.delete(cacheKeyStatus)
    }
}