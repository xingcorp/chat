import { Parent, ResolveField, Resolver } from "@nestjs/graphql";
import {
    LearnLesson,
} from "@models/entities";
import { LoggerService } from "@core/common/logger.service";
import { StorageService } from "@core/storage/storage.service";
import { RedisService } from "@core/common/redis.service";
import { RedisKey } from "@core/common/common.type";
import { RequestContext } from "@common/context/request.context";
import { File } from "@core/storage/objects/file";
import { isArray } from "lodash";


@Resolver(_of => LearnLesson)
export class LearnLessonResolver {
    logger = new LoggerService(LearnLessonResolver.name)
    constructor(
        private readonly storageService: StorageService,
        private redisService: RedisService,
    ) {
    }

    @ResolveField('attachments', _return => [File], { nullable: true })
    async avatars(
        @Parent() root: LearnLesson
    ) {
        try {
            if (!root.attachmentIds || !root.attachmentIds?.length) return []

            const cachedFilesKey = await this.redisService.get(RedisKey.ELearningLessonAttachment(root.id));

            if (cachedFilesKey && isArray(JSON.parse(cachedFilesKey))) {
                return JSON.parse(cachedFilesKey)
            }

            const { data } = await this.storageService.getFilesDetail(RequestContext.currentToken(), root.attachmentIds)
            await this.redisService.setWithTtl(RedisKey.ELearningLessonAttachment(root.id), JSON.stringify(data?.files), 60 * 60 * 24)

            return data?.files ?? []
        } catch (error) {
            this.logger.error(`Field avatars`, error);
            return []
        }
    }
}