import { createParamDecorator, ExecutionContext, SetMetadata } from '@nestjs/common'
import { GqlExecutionContext } from '@nestjs/graphql'

export const CurrentRequest = createParamDecorator(
  async (_data: string, ctx: ExecutionContext) => {
    const { req } = GqlExecutionContext.create(ctx).getContext()
    return req
  }
)

export const AccessToken = createParamDecorator(
  async (_data: string, ctx: ExecutionContext) => {
    const { req } = GqlExecutionContext.create(ctx).getContext()
    const bearToken = req.headers['authorization']
    return bearToken ? bearToken.split(' ')[1] : null
  }
)

export const BearerAccessToken = createParamDecorator(
  async (_data: string, ctx: ExecutionContext) => {
    const { req } = GqlExecutionContext.create(ctx).getContext()
    return req.headers['authorization']
  }
)

export const RestAccessToken = createParamDecorator(
  async (_data: string, ctx: ExecutionContext) => {
    const req = ctx.switchToHttp().getRequest()
    const bearToken = req.headers['authorization']
    return bearToken ? bearToken.split(' ')[1] : null
  }
)

export const FowardAuthentication = () => SetMetadata("isFowardAuthentication", true);