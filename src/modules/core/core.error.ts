import { ApolloError } from 'apollo-server-express'

export class BaseError extends ApolloError {
  public code = '500'
  public baseMsg = 'Unexpected error'
  constructor(code: string, message: string, extensions?: Record<string, any>) {
    super(
      JSON.stringify({
        code: code,
        message: message,
        extensions: extensions
      }),
      code,
      null
    )
    this.code = code
    this.baseMsg = message
  }
}

export const HttpError = {
  NoContent: new BaseError('204', 'No Content'),
  BadRequest: new BaseError('400', 'Bad Request'),
  Unauthorized: new BaseError('401', 'Unauthorized'),
  Forbidden: new BaseError('403', 'Forbidden'),
  PreconditionRequired: new BaseError('428', 'Precondition Required'),
  InternalServerError: new BaseError('500', 'Internal Server Error'),
  NotImplemented: new BaseError('501', 'Not Implemented')
}
