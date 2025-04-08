import { Parent, ResolveField, Resolver } from "@nestjs/graphql";
import {
    LearnAddress,
    LearnCourse,
    LearnProject,
    LearnSection,
    LearnStudent,
    OfficeUser,
} from "@models/entities";
import { AddressLearningRepo, OfficeUserRepo, ProjectLearningRepo, SectionLearningRepo, StudentLearningRepo } from "@models/repositories";
import { LoggerService } from "@core/common/logger.service";
import { In } from "typeorm";


@Resolver(_of => LearnCourse)
export class LearnCourseResolver {
    logger = new LoggerService(LearnCourseResolver.name)
    constructor(
        private sectionLearningRepo: SectionLearningRepo,
        private studentLearningRepo: StudentLearningRepo,
        private projectLearningRepo: ProjectLearningRepo,
        private officeUserRepo: OfficeUserRepo,
        private addressLearningRepo: AddressLearningRepo,
    ) {
    }

    @ResolveField('sections', _return => [LearnSection], { nullable: true })
    async sections(
        @Parent() root: LearnCourse
    ) {
        try {
            if (root.sections) {
                return root.sections
            }
            return await this.sectionLearningRepo.getManyBy({ courseId: root.id }, ['lessons'])
        } catch (error) {
            this.logger.error(`Field sections`, error);
            return []
        }
    }

    @ResolveField('students', _return => [LearnStudent], { nullable: true })
    async students(
        @Parent() root: LearnCourse
    ) {
        try {
            if (root.students) {
                return root.students
            }
            return await this.studentLearningRepo.getManyBy({ courseId: root.id })
        } catch (error) {
            this.logger.error(`Field students`, error);
            return []
        }
    }

    @ResolveField('teacher', _return => OfficeUser, { nullable: true })
    async teacher(
        @Parent() root: LearnCourse
    ) {
        try {
            if (root.teacher) {
                return root.teacher
            }
            if (!root.teacherId) return null

            return await this.officeUserRepo.getPublicProfileUser(root.teacherId)
        } catch (error) {
            this.logger.error(`Field teacher`, error);
            return null
        }
    }

    @ResolveField('project', _return => LearnProject, { nullable: true })
    async project(
        @Parent() root: LearnCourse
    ) {
        try {
            if (!root.projectId || root.project) {
                return root.project
            }

            return await this.projectLearningRepo.getCachedById(root.projectId)
        } catch (error) {
            this.logger.error(`Field project`, error);
            return []
        }
    }

    @ResolveField('trainingAddresses', _return => [LearnAddress], { nullable: true })
    async trainingAddresses(
        @Parent() root: LearnCourse
    ) {
        try {
            if (!root.trainingAddressIds) {
                return []
            }
            return await this.addressLearningRepo.getManyBy({ id: In(root.trainingAddressIds) })
        } catch (error) {
            this.logger.error(`Field trainingAddresses`, error);
            return []
        }
    }
}