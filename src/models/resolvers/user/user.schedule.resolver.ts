import { Parent, ResolveField, Resolver } from "@nestjs/graphql";
import {
    LearnStudent,
    UserSchedule,
} from "../../entities";
import { StudentLearningRepo } from "@models/repositories";
import { LoggerService } from "@core/common/logger.service";

@Resolver(_of => UserSchedule)
export class OfficeUserFieldResolver {
    logger = new LoggerService(OfficeUserFieldResolver.name)

    constructor(
        private readonly studentLearningRepo: StudentLearningRepo,
    ) { }

    @ResolveField('learnStudent', _return => LearnStudent, { nullable: true })
    async address(
        @Parent() root: UserSchedule
    ) {
        try {
            if (!root.learnStudentId || root.learnStudent) {
                return root.learnStudent
            }

            return this.studentLearningRepo.getCachedById(root.learnStudentId)
        } catch (error) {
            this.logger.error(`Field learnStudent`, error);
            return null
        }
    }
}