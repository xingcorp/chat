import { Args, Mutation, Resolver,Query } from "@nestjs/graphql";
import { AddressLearningService } from "./address.learning.service";
import { LearnAddress } from "@models/entities";
import {  SetMetadata, UseInterceptors } from "@nestjs/common";
import { ServiceActions, ServiceKeys, UserType } from "@core/middleware/guard/service.action";
import { LearningAddressCreateInput, LearningAddressUpdateInput, LearningAddressUpsertInput, AddressLearningFilterInput } from "./dto/address.learning.args";
import { LearningAddressResponse } from "./dto/address.response";
import { ErrorInterceptor } from "@interceptors/error.interceptor";
import { FixedDataOrgChartUserAllAndWChildInterceptor } from "@interceptors/org-chart.interceptor";

@Resolver()
export class AddressLearningResolver {
    constructor(private readonly service: AddressLearningService) {}

    @Mutation(() => LearnAddress, {name: 'manageLearningAddressCreate', nullable:true})
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    @SetMetadata(ServiceKeys.UserType, [UserType.SYSTEM_USER])
    @UseInterceptors(ErrorInterceptor)
    @UseInterceptors(FixedDataOrgChartUserAllAndWChildInterceptor)
    async manageLearningAddressCreate(
        @Args('arguments' , {nullable:false}) args: LearningAddressCreateInput
    ): Promise<LearnAddress> {
        return this.service.create(args)
    }

    @Mutation(() => LearnAddress, {name: 'manageLearningAddressUpdate', nullable: true})
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    @SetMetadata(ServiceKeys.UserType, [UserType.SYSTEM_USER])
    @UseInterceptors(ErrorInterceptor)
    @UseInterceptors(FixedDataOrgChartUserAllAndWChildInterceptor)
    async manageLearningAddressUpdate(
        @Args('arguments', {nullable: false}) args: LearningAddressUpdateInput,
    ): Promise<LearnAddress> {
        return this.service.update(args)
    }

    @Mutation(() => LearnAddress, {name: 'manageLearningAddressUpsert', nullable: true})
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    @SetMetadata(ServiceKeys.UserType, [UserType.SYSTEM_USER])
    @UseInterceptors(ErrorInterceptor)
    @UseInterceptors(FixedDataOrgChartUserAllAndWChildInterceptor)
    async manageLearningAddressUpsert(
        @Args('arguments', {nullable: false}) args: LearningAddressUpsertInput,
    ): Promise<LearnAddress> {
        return this.service.upsert(args)
    }

    @Query(() => LearnAddress, {name: 'manageLearningAddressGet', nullable: true})
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    @SetMetadata(ServiceKeys.UserType, [UserType.SYSTEM_USER])
    @UseInterceptors(FixedDataOrgChartUserAllAndWChildInterceptor)
    async manageLearningAddressGet(
        @Args('id', {nullable: false}) id: string,
    ): Promise<LearnAddress> {
        return this.service.get(id)
    }

    @Query(() => LearningAddressResponse, {name: 'manageLearningAddressList', nullable: true})
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    @SetMetadata(ServiceKeys.UserType, [UserType.SYSTEM_USER])
    @UseInterceptors(ErrorInterceptor)
    @UseInterceptors(FixedDataOrgChartUserAllAndWChildInterceptor)
    async manageLearningAddressList(
        @Args('filter', {nullable: true}) filter: AddressLearningFilterInput,
    ): Promise<LearningAddressResponse> {
        return this.service.list(filter)
    }

    @Mutation(() => String, {name: 'manageLearningAddressRemove', nullable: true})
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    @SetMetadata(ServiceKeys.UserType, [UserType.SYSTEM_USER])
    @UseInterceptors(ErrorInterceptor)
    @UseInterceptors(FixedDataOrgChartUserAllAndWChildInterceptor)
    async manageLearningAddressRemove(
        @Args('id', {nullable: false}) id: string,
    ): Promise<string> {
        return this.service.remove(id)
    }
}