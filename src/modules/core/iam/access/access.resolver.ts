import { Mutation, Query, Resolver } from '@nestjs/graphql'
import { Request } from 'express'
import { CurrentRequest } from '../../middleware/decorator/request.decorator'
import { AccessService } from '../access/access.service'
import { AccessPermission } from './access.response'

@Resolver()
export class AccessResolver {
    constructor(
        private readonly accessService: AccessService
    ) { }

    @Query(() => AccessPermission, { name: "iamAccessGetPermission" })
    async get(@CurrentRequest() request: Request): Promise<AccessPermission> {
        return await this.accessService.forwardRequest(request)
    }
}
