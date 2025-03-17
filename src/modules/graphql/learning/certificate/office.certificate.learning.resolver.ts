import { Args, Query, Resolver } from '@nestjs/graphql';
import { LearnCertification } from "@models/entities";
import { SetMetadata, UseInterceptors } from "@nestjs/common";
import { ServiceActions, ServiceKeys, UserType } from "@core/middleware/guard/service.action";
import { FixedDataOrgChartUserAllAndWChildInterceptor } from "@interceptors/org-chart.interceptor";
import { LearningCertificateResponse } from "@modules/graphql/learning/certificate/dto/certificate.learning.response";
import { ErrorInterceptor } from "@interceptors/error.interceptor";
import { LearningCertificateFilterInput } from "@modules/graphql/learning/certificate/dto/certificate.learning.arg";
import { CertificateLearningService } from "@modules/graphql/learning/certificate/certificate.learning.service";

@Resolver()
export class OfficeCertificateLearningResolver {

    constructor(private readonly service: CertificateLearningService) {}

    @Query(() => LearnCertification, {name: 'officeLearningCertificateGet', nullable: true})
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    @SetMetadata(ServiceKeys.UserType, [UserType.NORMAL_USER])
    @UseInterceptors(FixedDataOrgChartUserAllAndWChildInterceptor)
    async officeLearningCertificateGet(
        @Args('id', {nullable: false}) id: string,
    ): Promise<LearnCertification> {
        return this.service.get(id)
    }

    @Query(() => LearningCertificateResponse, {name: 'officeLearningCertificateList', nullable: true})
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    @SetMetadata(ServiceKeys.UserType, [UserType.NORMAL_USER])
    @UseInterceptors(FixedDataOrgChartUserAllAndWChildInterceptor)
    @UseInterceptors(ErrorInterceptor)
    async officeLearningCertificateList(
        @Args('filter', {nullable: true}) filter: LearningCertificateFilterInput,
    ): Promise<LearningCertificateResponse> {
        return this.service.list(filter)
    }
}
