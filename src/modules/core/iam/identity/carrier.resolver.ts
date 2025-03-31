import { forwardRef, Inject } from '@nestjs/common'
import { Args, Field, InputType, Query, Resolver } from '@nestjs/graphql'
import { Request } from 'express'
import { CurrentRequest } from '../../middleware/decorator/request.decorator'
import { CarrierResponse } from './identity.response'
import { IdentityService } from './identity.service'

@InputType()
export class CarrierFilterArgs {
  @Field({ nullable: true, defaultValue: 0 })
  page?: number

  @Field({ nullable: true, defaultValue: 100 })
  size?: number

  @Field({ nullable: true })
  keyword: string
}

@Resolver()
export class CarrierResolver {
  constructor(
    @Inject(forwardRef(() => IdentityService))
    private readonly identityService: IdentityService
  ) {}

  @Query(() => CarrierResponse, { name: 'identityCarrierGetList' })
  async getList(
    @Args('filter', { nullable: true }) _filter: CarrierFilterArgs,
    @CurrentRequest() request: Request
  ) {
    return this.identityService.forwardRequest(request)
  }
}
