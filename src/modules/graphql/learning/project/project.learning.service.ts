import { Injectable } from '@nestjs/common';
import {
    LearningProjectCreateInput, LearningProjectFilterInput,
    LearningProjectUpdateInput, LearningProjectUpsertInput
} from "@modules/graphql/learning/project/dto/project.learning.arg";
import { RequestContext } from "@common/context/request.context";
import { OfficeError } from "@common/office.error";
import { LearningUserPinnedRepo, ProjectLearningRepo, RequirementLearningRepo } from "@models/repositories";
import { LearningUserPinned } from "@models/entities";
import { RedisKey } from '@core/common/common.type';
import { RedisService } from '@core/common/redis.service';
import { CourseLearningService } from '../course/course.learning.service';
import { LearnProjectStatusEnum } from '@enum/learning/learning.enum';

@Injectable()
export class ProjectLearningService {

    constructor(
        private readonly projectLearningRepo: ProjectLearningRepo,
        private readonly redisService: RedisService,
        private readonly courseLearningService: CourseLearningService,
        private readonly learningUserPinnedRepo: LearningUserPinnedRepo,
    ) {
    }

    private async checkAndGetUserAction() {
        const user = await RequestContext.currentUser()

        if (!user) {
            throw OfficeError.AdminNeedLinkUser
        }

        return user
    }

    async create(args: LearningProjectCreateInput) {

        const project = this.projectLearningRepo.create({
            ...args,
            startDate: args.startDate ? new Date(args.startDate) : null,
            endDate: args.endDate ? new Date(args.endDate) : null,
        })

        project.createdBy = RequestContext.currentId()
        project.orgChart = await RequestContext.getRootOrg()

        await project.save()

        return project
    }

    async update(args: LearningProjectUpdateInput) {
        const project = args.project
        if (![LearnProjectStatusEnum.DRAFT, LearnProjectStatusEnum.ACTIVE].includes(project.status)) {
            throw OfficeError.LearningProjectStatusCannotUpdate
        }

        if (args.isHide === true && project.status != LearnProjectStatusEnum.CLOSE) {
            const isProjectHasStudent = await this.courseLearningService.isProjectHasStudent(project.id)
            if (isProjectHasStudent) {
                throw OfficeError.LearningProjectStatusCannotHide
            }
        }

        if (args.status === LearnProjectStatusEnum.CLOSE) {
            const isCoursesOfProjectIsEnd = await this.courseLearningService.isCoursesOfProjectIsEnd(project.id)
            if (isCoursesOfProjectIsEnd) {
                throw OfficeError.LearningProjectHaveActiveCourse
            }
        }
        if (args.startDate) {
            project.startDate = new Date(args.startDate)
        } else if (args.startDate === null) {
            project.startDate = null
        }

        if (args.endDate) {
            project.endDate = new Date(args.endDate)
        } else if (args.endDate === null) {
            project.endDate = null
        }

        if (args.avatarIds != undefined) {
            project.avatarIds = args.avatarIds
        }

        if (args.videoIds != undefined) {
            project.videoIds = args.videoIds
        }

        if (args.skills) {
            await this.redisService.delete(RedisKey.ELearningProjectLearningSkill(project.id))
            project.skills = args.skills
        }

        project.status = args.status ?? project.status
        project.isHide = args.isHide != undefined ? args.isHide : project.isHide
        project.code = args.code ?? project.code
        project.name = args.name ?? project.name
        project.maxNumberOfStudent = args.maxNumberOfStudent ?? project.maxNumberOfStudent
        project.timeType = args.timeType ?? project.timeType
        project.dayOfEvent = args.dayOfEvent ?? project.dayOfEvent
        project.summary = args.summary ?? project.summary
        project.scoreToPass = args.scoreToPass ?? project.scoreToPass
        project.timeToPass = args.timeToPass ?? project.timeToPass
        project.content = args.content ?? project.content
        project.departments = args.departments ?? project.departments
        project.certificates = args.certificates ?? project.certificates
        project.requiredLearnExaminationIds = args.requiredLearnExaminationIds ?? project.requiredLearnExaminationIds
        project.requiredLearnProjectIds = args.requiredLearnProjectIds ?? project.requiredLearnProjectIds
        project.requiredSurveyIds = args.requiredSurveyIds ?? project.requiredSurveyIds
        project.requiredCertificateIds = args.requiredCertificateIds ?? project.requiredCertificateIds
        project.updatedBy = RequestContext.currentId()
        await this.projectLearningRepo.manager.transaction(async transactionalEntityManager => {
            await transactionalEntityManager.save(
                project
            );

            if (args.isPin != undefined) {
                if (args.isPin == true) {
                    await transactionalEntityManager.save(
                        this.learningUserPinnedRepo.create({
                            userId: RequestContext.currentId(),
                            projectId: project.id
                        })
                    )
                } else {
                    await transactionalEntityManager
                        .createQueryBuilder()
                        .delete()
                        .from(LearningUserPinned)
                        .where('userId = :userId', { userId: RequestContext.currentId() })
                        .andWhere('projectId = :projectId', { projectId: project.id })
                        .execute();
                }
            }
        })


        return project
    }

    upsert(args: LearningProjectUpsertInput) {
        if (args.projectId) {
            return this.update(args)
        }

        return this.create(args)
    }

    get(id: string) {
        return this.projectLearningRepo.getBy({ id })
    }

    async list(filter: LearningProjectFilterInput) {
        const [data, total] = await this.projectLearningRepo.listByFilter(filter)

        return {
            total: total as number,
            count: data.length,
            records: data
        }
    }

    async remove(id: string) {
        const entity = await this.get(id)

        if (!entity) {
            throw OfficeError.LearningProjectNotFound
        }

        const isProjectHasStudent = await this.courseLearningService.isProjectHasStudent(id)
        if (isProjectHasStudent) {
            throw OfficeError.LearningProjectHasStudent
        }

        entity.deletedBy = RequestContext.currentId()
        await entity.save()
        await entity.softRemove()

        return id;
    }
}
