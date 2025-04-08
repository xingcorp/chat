import { forwardRef, Inject } from '@nestjs/common'
import { Args, Field, InputType, Query, Resolver } from '@nestjs/graphql'
import { Request } from 'express'
import { CurrentRequest } from '../../middleware/decorator/request.decorator'
import { BankResponse } from './identity.response'
import { IdentityService } from './identity.service'

@InputType()
export class BankFilterArgs {
  @Field({ nullable: true, defaultValue: 0 })
  page?: number

  @Field({ nullable: true, defaultValue: 100 })
  size?: number

  @Field({ nullable: true })
  keyword: string
}

@Resolver()
export class BankResolver {
  constructor(
    @Inject(forwardRef(() => IdentityService))
    private readonly identityService: IdentityService
  ) {}

  @Query(() => BankResponse, { name: 'identityBankGetList' })
  async getList(
    @Args('filter', { nullable: true }) _filter: BankFilterArgs,
    @CurrentRequest() request: Request
  ): Promise<BankResponse> {
    return this.identityService.forwardRequest(request)
  }
}
