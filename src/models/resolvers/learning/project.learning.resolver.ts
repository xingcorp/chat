import { Parent, ResolveField, Resolver } from "@nestjs/graphql";
import {
    LearnCertification, LearnCourse,
    LearnProject,
    LearnSkill,
    OfficeOrgChart
} from "@models/entities";
import { LearningUserPinnedRepo, ProjectLearningRepo } from "@models/repositories";
import { RequestContext } from "@common/context/request.context";
import { File } from "@core/storage/objects/file";
import { forwardRef, Inject } from "@nestjs/common";
import { StorageService } from "@core/storage/storage.service";
import { RedisService } from "@core/common/redis.service";
import { RedisKey } from "@core/common/common.type";
import { LoggerService } from "@core/common/logger.service";
import { isArray } from "lodash";

@Resolver(_of => LearnProject)
export class ProjectLearningResolver {
    logger = new LoggerService(ProjectLearningResolver.name)
    constructor(
        @Inject(forwardRef(() => StorageService))
        private readonly storageService: StorageService,
        private projectLearningRepo: ProjectLearningRepo,
        private redisService: RedisService,
        private learningUserPinnedRepo: LearningUserPinnedRepo,
    ) {
    }

    @ResolveField('avatars', _return => [File], { nullable: true })
    async avatars(
        @Parent() root: LearnProject
    ) {
        try {
            if (!root.avatarIds || !root.avatarIds?.length) return []

            const cachedFilesKey = await this.redisService.get(RedisKey.ELearningProjectAvatar(root.id));
            if (cachedFilesKey && isArray(JSON.parse(cachedFilesKey))) {
                return JSON.parse(cachedFilesKey)
            }

            const { data } = await this.storageService.getFilesDetail(RequestContext.currentToken(), root.avatarIds)
            await this.redisService.setWithTtl(RedisKey.ELearningProjectAvatar(root.id), JSON.stringify(data?.files), 60 * 60 * 24)

            return data?.files ?? []
        } catch (error) {
            this.logger.error(`Field avatars`, error);
            return []
        }
    }

    @ResolveField('videos', _return => [File], { nullable: true })
    async videos(
        @Parent() root: LearnProject
    ) {
        try {

            if (!root.videoIds || !root.videoIds?.length) return []
            const cachedFilesKey = await this.redisService.get(RedisKey.ELearningProjectVideo(root.id));
            if (cachedFilesKey && isArray(JSON.parse(cachedFilesKey))) {
                return JSON.parse(cachedFilesKey)
            }

            const { data } = await this.storageService.getFilesDetail(RequestContext.currentToken(), root.videoIds)
            await this.redisService.setWithTtl(RedisKey.ELearningProjectVideo(root.id), JSON.stringify(data?.files), 60 * 60 * 24)

            return data?.files ?? []
        } catch (error) {
            this.logger.error(`Field videos`, error);
            return []
        }
    }

    @ResolveField('skills', _return => [LearnSkill], { nullable: true })
    async skills(
        @Parent() root: LearnProject
    ) {
        const _root = await this.projectLearningRepo.getBy({ id: root.id }, ['skills'])
        return _root.skills
    }

    @ResolveField('certificates', _return => [LearnCertification], { nullable: true })
    async certificates(
        @Parent() root: LearnProject
    ) {
        const _root = await this.projectLearningRepo.getBy({ id: root.id }, ['certificates'])
        return _root.certificates
    }

    @ResolveField('departments', _return => [OfficeOrgChart], { nullable: true })
    async departments(
        @Parent() root: LearnProject
    ) {
        const _root = await this.projectLearningRepo.getBy({ id: root.id }, ['departments'])
        return _root.departments
    }

    @ResolveField('courses', _return => [LearnCourse], { nullable: true })
    async courses(
        @Parent() root: LearnProject
    ) {
        const _root = await this.projectLearningRepo.getBy({ id: root.id }, ['courses'])
        return _root.courses
    }

    @ResolveField('isPin', _return => Boolean, { defaultValue: false })
    async isPin(
        @Parent() root: LearnProject
    ) {
        try {
            const isPinned = await this.learningUserPinnedRepo.getBy({ projectId: root.id, userId: RequestContext.currentId() })
            return !!isPinned
        } catch (error) {
            this.logger.error(`Field isPin`, error);
            return false
        }
    }
}