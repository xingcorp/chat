import { BaseError } from '../core.error'

export const buildExceptionResponse = (exception) => {
  const exceptionClassName = exception.constructor.name
  switch (exceptionClassName) {
    case 'TypeError': {
      return new BaseError('TypeError', exception.stack)
    }
    case 'QueryFailedError': {
      return new BaseError('QueryFailedError', exception.driverError.toString())
    }
    case 'ApolloError': {
      const error = exception.graphQLErrors ? exception.graphQLErrors[0] : null
      if (error) {
        return new BaseError(error.code, error.message)
      } else if (exception.networkError) {
        const result = exception.networkError.result
        if (result && result.errors && result.errors.length > 0) {
          const err = result.errors[0]
          return new BaseError(
            exception.networkError.statusCode
              ? `${exception.networkError.statusCode}`
              : '500',
            err.message ? err.message : 'Unexpected error'
          )
        } else {
          return new BaseError(
            `${exception.networkError.statusCode}`,
            `${exception.networkError.message}`
          )
        }
      } else {
        const message = exception.message.replace('GraphQL error: ', '')
        return new BaseError('500', message)
      }
    }
    default: {
      return new BaseError('Exeption message', exception.toString())
    }
  }
}
