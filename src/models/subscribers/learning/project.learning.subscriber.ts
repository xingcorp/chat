import { LearnProject } from "@models/entities";
import { Injectable } from "@nestjs/common";
import { Connection, EntitySubscriberInterface, InsertEvent, UpdateEvent } from "typeorm";
import { RedisService } from "@core/common/redis.service";
import { RedisKey } from "@core/common/common.type";
import { StorageService } from "@core/storage/storage.service";
import { RequestContext } from "@common/context/request.context";
import * as _ from 'lodash'
@Injectable()
export class LearnProjectSubscriber implements EntitySubscriberInterface<LearnProject> {
    constructor(
        readonly connection: Connection,
        private readonly redisService: RedisService,
        private readonly storageService: StorageService
    ) {
        connection.subscribers.push(this);
    }

    listenTo() {
        return LearnProject
    }

    async afterUpdate(event: UpdateEvent<LearnProject>) {
        const learnProject = event.entity;
        const key = RedisKey.ELearningProjectLearning(learnProject.id)
        await this.redisService.delete(key)
        await this.redisService.setWithTtl(key, JSON.stringify(learnProject))

        // Filter out array fields that haven't actually changed
        event.updatedColumns = event.updatedColumns.filter(column => {
            const oldValue = event.databaseEntity[column.propertyName];
            const newValue = learnProject[column.propertyName];

            if (Array.isArray(oldValue) && Array.isArray(newValue)) {
                return JSON.stringify(oldValue) !== JSON.stringify(newValue); // Deep compare arrays
            }

            return oldValue !== newValue;
        });

        await Promise.all(event.updatedColumns.map(col => this.redisService.delete(`${col.propertyName}:${learnProject.id}`)))
        const removeAvatarIds = _.difference(event.databaseEntity.avatarIds, learnProject.avatarIds)
        const addAvatarIds = _.difference(learnProject.avatarIds, event.databaseEntity.avatarIds)
        if (addAvatarIds.length > 0) {
            await this.storageService.activeUsingFiles(RequestContext.currentToken(), addAvatarIds)
        }
        if (removeAvatarIds.length > 0) {
            await Promise.all(removeAvatarIds.map(id => this.storageService.deleteFile(RequestContext.currentToken(), id)))
        }

        const removeVideoIds = _.difference(event.databaseEntity.videoIds, learnProject.videoIds)
        const addVideoIds = _.difference(learnProject.videoIds, event.databaseEntity.videoIds)
        if (addVideoIds.length > 0) {
            await this.storageService.activeUsingFiles(RequestContext.currentToken(), addVideoIds)
        }
        if (removeVideoIds.length > 0) {
            await Promise.all(removeVideoIds.map(id => this.storageService.deleteFile(RequestContext.currentToken(), id)))
        }
    }

    async afterInsert(event: InsertEvent<LearnProject>) {
        const learnProject = event.entity;
        if (learnProject.avatarIds && learnProject.avatarIds.length > 0) {
            await this.storageService.activeUsingFiles(RequestContext.currentToken(), learnProject.avatarIds)
        }

        if (learnProject.videoIds) {
            await this.storageService.activeUsingFiles(RequestContext.currentToken(), learnProject.avatarIds)
        }
    }
}