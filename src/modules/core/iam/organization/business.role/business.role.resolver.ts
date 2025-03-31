import { forwardRef, Inject, SetMetadata } from '@nestjs/common'
import { Resolver, Query } from '@nestjs/graphql'
import { CurrentRequest } from '../../../middleware/decorator/request.decorator'
import { BusinessRoleResponse } from './business.role.response'
import { BusinessRoleService } from './business.role.service'
import { Request } from 'express'

@Resolver()
export class BusinessRoleResolver {
    constructor(
        @Inject(forwardRef(() => BusinessRoleService))
        private readonly businessRoleService: BusinessRoleService
    ) { }

    @Query(() => BusinessRoleResponse, { name: 'appBusinessRoleAvailableList' })
    async availableList(
        @CurrentRequest() request: Request
    ): Promise<BusinessRoleResponse> {
        return await this.businessRoleService.forwardRequest(request)
    }
}
