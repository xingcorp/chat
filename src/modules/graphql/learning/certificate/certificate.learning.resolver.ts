import { Args, Mutation, Query, Resolver } from '@nestjs/graphql';
import { LearnCertification } from "@models/entities";
import { SetMetadata, UseInterceptors } from "@nestjs/common";
import { ServiceActions, ServiceKeys, UserType } from "@core/middleware/guard/service.action";
import { ErrorInterceptor } from "@interceptors/error.interceptor";
import { FixedDataOrgChartUserAllAndWChildInterceptor } from "@interceptors/org-chart.interceptor";
import { CertificateLearningService } from "@modules/graphql/learning/certificate/certificate.learning.service";
import {
    LearningCertificateCreateInput, LearningCertificateFilterInput,
    LearningCertificateUpdateInput, LearningCertificateUpsertInput
} from "@modules/graphql/learning/certificate/dto/certificate.learning.arg";
import { LearningCertificateResponse } from "@modules/graphql/learning/certificate/dto/certificate.learning.response";

@Resolver()
export class CertificateLearningResolver {
    constructor(private readonly service: CertificateLearningService) {}

    @Mutation(() => LearnCertification, {name: 'manageLearningCertificateCreate', nullable: true})
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    @SetMetadata(ServiceKeys.UserType, [UserType.SYSTEM_USER])
    @UseInterceptors(ErrorInterceptor)
    @UseInterceptors(FixedDataOrgChartUserAllAndWChildInterceptor)
    async manageLearningCertificateCreate(
        @Args('arguments', {nullable: false}) args: LearningCertificateCreateInput,
    ): Promise<LearnCertification> {
        return this.service.create(args)
    }

    @Mutation(() => LearnCertification, {name: 'manageLearningCertificateUpdate', nullable: true})
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    @SetMetadata(ServiceKeys.UserType, [UserType.SYSTEM_USER])
    @UseInterceptors(ErrorInterceptor)
    @UseInterceptors(FixedDataOrgChartUserAllAndWChildInterceptor)
    async manageLearningCertificateUpdate(
        @Args('arguments', {nullable: false}) args: LearningCertificateUpdateInput,
    ): Promise<LearnCertification> {
        return this.service.update(args)
    }

    @Mutation(() => LearnCertification, {name: 'manageLearningCertificateUpsert', nullable: true})
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    @SetMetadata(ServiceKeys.UserType, [UserType.SYSTEM_USER])
    @UseInterceptors(ErrorInterceptor)
    @UseInterceptors(FixedDataOrgChartUserAllAndWChildInterceptor)
    async manageLearningCertificateUpsert(
        @Args('arguments', {nullable: false}) args: LearningCertificateUpsertInput,
    ): Promise<LearnCertification> {
        return this.service.upsert(args)
    }

    @Query(() => LearnCertification, {name: 'manageLearningCertificateGet', nullable: true})
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    @SetMetadata(ServiceKeys.UserType, [UserType.SYSTEM_USER])
    @UseInterceptors(FixedDataOrgChartUserAllAndWChildInterceptor)
    async manageLearningCertificateGet(
        @Args('id', {nullable: false}) id: string,
    ): Promise<LearnCertification> {
        return this.service.get(id)
    }

    @Query(() => LearningCertificateResponse, {name: 'manageLearningCertificateList', nullable: true})
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    @SetMetadata(ServiceKeys.UserType, [UserType.SYSTEM_USER])
    @UseInterceptors(FixedDataOrgChartUserAllAndWChildInterceptor)
    @UseInterceptors(ErrorInterceptor)
    async manageLearningCertificateList(
        @Args('filter', {nullable: true}) filter: LearningCertificateFilterInput,
    ): Promise<LearningCertificateResponse> {
        return this.service.list(filter)
    }

    @Mutation(() => String, {name: 'manageLearningCertificateRemove', nullable: true})
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    @SetMetadata(ServiceKeys.UserType, [UserType.SYSTEM_USER])
    @UseInterceptors(ErrorInterceptor)
    @UseInterceptors(FixedDataOrgChartUserAllAndWChildInterceptor)
    async manageLearningCertificateRemove(
        @Args('id', {nullable: false}) id: string,
    ): Promise<string> {
        return this.service.remove(id)
    }
}
