import { CallHandler, ExecutionContext, Injectable, NestInterceptor } from '@nestjs/common';
import { Observable } from 'rxjs';
import { GqlExecutionContext } from "@nestjs/graphql";

export enum ValidateDataType {
  Default = 'Default',
  BulkUpsert = 'BulkUpsert'
}

@Injectable()
export class ValidateDataTypeBulkUpsertInterceptor implements NestInterceptor {
  intercept(context: ExecutionContext, next: CallHandler): Observable<any> {
    const {req} = GqlExecutionContext.create(context).getContext()

    req.validateDataType = ValidateDataType.BulkUpsert

    return next.handle();
  }
}
