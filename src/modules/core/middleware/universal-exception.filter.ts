import { LoggerService } from '@core/common/logger.service';
import {
  ExceptionFilter,
  Catch,
  ArgumentsHost,
  WsExceptionFilter,
} from '@nestjs/common';

@Catch()
export class UniversalExceptionFilter implements ExceptionFilter, WsExceptionFilter {
  logger = new LoggerService(UniversalExceptionFilter.name);

  catch(exception: unknown, host: ArgumentsHost) {
    // const ctxType = host.getType() as string;
    this.logger.error(`Exception: `, exception);
    // if (ctxType === 'http') {
    //   this.handleHttpException(exception, host);
    // } else if (ctxType === 'graphql') {
    //   this.handleGraphQLException(exception, host);
    // } else if (ctxType === 'ws') {
    //   this.handleWebSocketException(exception, host);
    // } else {
    //   console.error('Unhandled exception:', exception);
    // }

  }
  // private handleHttpException(exception: unknown, host: ArgumentsHost) {
  //   const ctx = host.switchToHttp();
  //   const response = ctx.getResponse();
  //   const request = ctx.getRequest();

  //   const status =
  //     exception instanceof HttpException ? exception.getStatus() : 500;

  //   console.error('[REST API] Exception:', exception);

  //   response.status(status).json({
  //     statusCode: status,
  //     timestamp: new Date().toISOString(),
  //     path: request.url,
  //     errorMessage: exception instanceof Error ? exception.message : 'Unknown error',
  //   });
  // }

  // private handleGraphQLException(exception: unknown, host: ArgumentsHost) {
  //   const gqlHost = GqlArgumentsHost.create(host);
  //   console.error('[GraphQL] Exception:', exception);

  //   return new Error(exception instanceof Error ? exception.message : 'GraphQL Error');
  // }

  // private handleWebSocketException(exception: unknown, host: ArgumentsHost) {
  //   const client = host.switchToWs().getClient();
  //   console.error('[WebSocket] Exception:', exception);

  //   client.emit('error', {
  //     message: exception instanceof WsException ? exception.getError() : 'WebSocket Error',
  //   });
  // }
}
