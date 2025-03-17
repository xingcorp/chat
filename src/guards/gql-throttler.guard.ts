import { ExecutionContext, Injectable } from '@nestjs/common';
import { ThrottlerGuard } from "@nestjs/throttler";
import { GqlExecutionContext } from "@nestjs/graphql";
import { OfficeError } from "@common/office.error";

@Injectable()
export class GqlThrottlerGuard extends ThrottlerGuard {
  getRequestResponse(context: ExecutionContext) {
    const gqlCtx = GqlExecutionContext.create(context);
    const ctx = gqlCtx.getContext();
    return { req: ctx.req, res: ctx.req.res };
  }

  async throwThrottlingException(): Promise<void> {
    throw OfficeError.TooManyRequests;
  }
}