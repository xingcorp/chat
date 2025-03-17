import { Parent, ResolveField, Resolver } from "@nestjs/graphql";
import {
    LearnStudent,
    OfficeUser,
} from "@models/entities";
import { OfficeUserRepo } from "@models/repositories";
import { LoggerService } from "@core/common/logger.service";


@Resolver(_of => LearnStudent)
export class LearnStudentResolver {
    logger = new LoggerService(LearnStudentResolver.name)
    constructor(
        private officeUserRepo: OfficeUserRepo,
    ) { }

    @ResolveField('user', _return => OfficeUser, { nullable: true })
    async sections(
        @Parent() root: LearnStudent
    ) {
        try {
            if (root.user) {
                return root.user
            }
            return await this.officeUserRepo.getPublicProfileUser(root.userId)
        } catch (error) {
            this.logger.error(`Field user`, error);
            return []
        }
    }
}