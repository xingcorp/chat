import { LearnLesson } from "@models/entities";
import { Injectable } from "@nestjs/common";
import { Connection, EntitySubscriberInterface, InsertEvent, UpdateEvent } from "typeorm";
import { RedisService } from "@core/common/redis.service";
import { RedisKey } from "@core/common/common.type";
import { StorageService } from "@core/storage/storage.service";
import { RequestContext } from "@common/context/request.context";
import * as _ from 'lodash'
import { LoggerService } from "@core/common/logger.service";

@Injectable()
export class LearnLessonSubscriber implements EntitySubscriberInterface<LearnLesson> {
    logger = new LoggerService(LearnLessonSubscriber.name)
    constructor(
        readonly connection: Connection,
        private readonly redisService: RedisService,
        private readonly storageService: StorageService
    ) {
        connection.subscribers.push(this);
    }

    listenTo() {
        return LearnLesson
    }

    async afterUpdate(event: UpdateEvent<LearnLesson>) {
        const lesson = event.entity;

        const key = RedisKey.ELearningProjectLearning(lesson.id)
        await this.redisService.delete(key)
        await this.redisService.setWithTtl(key, JSON.stringify(lesson))

        // Filter out array fields that haven't actually changed
        event.updatedColumns = event.updatedColumns.filter(column => {
            const oldValue = event.databaseEntity[column.propertyName];
            const newValue = event.entity[column.propertyName];

            if (Array.isArray(oldValue) && Array.isArray(newValue)) {
                return JSON.stringify(oldValue) !== JSON.stringify(newValue); // Deep compare arrays
            }

            return oldValue !== newValue;
        });

        await Promise.all(event.updatedColumns.map(col => this.redisService.delete(`${col.propertyName}:${lesson.id}`)))

        const removeAttachmentIds = _.difference(event.databaseEntity.attachmentIds, lesson.attachmentIds)
        const addAttachmentIds = _.difference(lesson.attachmentIds, event.databaseEntity.attachmentIds)
        if (addAttachmentIds.length > 0) {
            await this.storageService.activeUsingFiles(RequestContext.currentToken(), addAttachmentIds)
        }
        if (removeAttachmentIds.length > 0) {
            await Promise.all(removeAttachmentIds.map(id => this.storageService.deleteFile(RequestContext.currentToken(), id)))
        }
    }

    async afterInsert(event: InsertEvent<LearnLesson>) {
        const lesson = event.entity;
        if (lesson.attachmentIds && lesson.attachmentIds.length > 0) {
            await this.storageService.activeUsingFiles(RequestContext.currentToken(), lesson.attachmentIds)
        }
    }
}