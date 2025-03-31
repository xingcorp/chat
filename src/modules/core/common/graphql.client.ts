import { ApolloClient, ApolloLink, DocumentNode, InMemoryCache } from 'apollo-boost'
import { Request } from 'express'
import { HttpError } from '../core.error'
import { buildExceptionResponse } from './error.builder'
import * as GQLTag from 'graphql-tag'
import * as CrossFetch from 'cross-fetch/polyfill'
import * as ApolloLinkHttp from 'apollo-link-http'

export const ORG_ID = process.env.ORGANITZATION_ID
export const SERVICE_CODE = process.env.SERVICE_CODE || 'office'
export const SERVICE_ID = process.env.SERVICE_ID
export const SYSTEM_SECRET = process.env.SYSTEM_SECRET

export class GraphQLClient {
  protected readonly graqhQlUrl = null
  protected readonly aplloClient = null
  constructor(graqhQlUrl: string) {
    this.graqhQlUrl = graqhQlUrl
    this.aplloClient = new ApolloClient({
      link: ApolloLinkHttp.createHttpLink({
        uri: graqhQlUrl,
        fetch: CrossFetch.fetch
      }),
      cache: new InMemoryCache()
    })
  }

  public async forwardRequest(request: Request) {
    try {
      const body: any = request.body
      const userToken = request.headers['authorization']

      const { operationName, query, variables } = body
      if (!query) {
        throw HttpError.BadRequest
      }

      const startTick = (new Date()).getTime()
      const { data } = await this.aplloClient.mutate({
        mutation: GQLTag.gql`${query}`,
        variables: variables,
        fetchPolicy: 'no-cache',
        context: {
          headers: {
            authorization: userToken,
            service_code: SERVICE_CODE,
            service_id: SERVICE_ID
          }
        }
      })
      console.log(`[GraphQLClient] forwardRequest finish: ${JSON.stringify({
        requestAt: startTick,
        responseAt: (new Date()).getTime(),
        processTime: (new Date()).getTime() - startTick
      })}`)

      const keys = Object.keys(data)
      if (!keys || keys.length === 0) {
        return data
      }

      if (keys.length === 1) {
        return data[keys[0]]
      }

      if (operationName && operationName !== undefined) {
        return data[operationName]
      }

      if (keys[0] !== '__typename') {
        return data[keys[0]]
      } else {
        return data[keys[1]]
      }
    } catch (error) {
      console.log(`[GraphQLClient] forwardRequest has error: ${error}`)
      // throw buildExceptionResponse(error)
    }
  }

  public sendQuery = async (
    token: string,
    schema: DocumentNode,
    variables: Record<string, any> = null
  ) => {
    try {
      if (!schema) {
        throw HttpError.BadRequest
      }

      const startTick = (new Date()).getTime()
      const { data } = await this.aplloClient.query({
        query: schema,
        variables: variables,
        fetchPolicy: 'no-cache',
        context: {
          headers: {
            authorization: token,
            service_code: SERVICE_CODE,
            service_id: SERVICE_ID
          }
        }
      })
      console.log(`[GraphQLClient] sendQuery finish: ${JSON.stringify({
        requestAt: startTick,
        responseAt: (new Date()).getTime(),
        processTime: (new Date()).getTime() - startTick
      })}`)

      const keys = Object.keys(data)
      return { data: keys && keys[0] ? data[keys[0]] : data }
    } catch (error) {
      console.log(`[GraphQLClient] sendQuery has error: ${error}`)
      return { error: buildExceptionResponse(error) }
    }
  }

  public sendMutation = async (
    token: string,
    schema: DocumentNode,
    variables: Record<string, any> = null
  ) => {
    try {
      if (!schema) {
        throw HttpError.BadRequest
      }

      const startTick = (new Date()).getTime()
      const { data } = await this.aplloClient.mutate({
        mutation: schema,
        variables: variables,
        fetchPolicy: 'no-cache',
        context: {
          headers: {
            authorization: token,
            service_code: SERVICE_CODE,
            service_id: SERVICE_ID
          }
        }
      })
      console.log(`[GraphQLClient] sendMutation finish: ${JSON.stringify({
        requestAt: startTick,
        responseAt: (new Date()).getTime(),
        processTime: (new Date()).getTime() - startTick
      })}`)

      const keys = Object.keys(data)
      return { data: keys && keys[0] ? data[keys[0]] : data }
    } catch (error) {
      console.log(`[GraphQLClient] sendMutation has error: ${error}`)
      return { error: buildExceptionResponse(error) }
    }
  }

  public sendMutationWithSecret = async (
    schema: DocumentNode,
    variables: Record<string, any> = null
  ) => {
    try {
      if (!schema) {
        throw HttpError.BadRequest
      }

      const startTick = (new Date()).getTime()
      const { data } = await this.aplloClient.mutate({
        mutation: schema,
        variables: variables,
        fetchPolicy: 'no-cache',
        context: {
          headers: {
            secret: SYSTEM_SECRET,
            service_code: SERVICE_CODE,
            service_id: SERVICE_ID
          }
        }
      })
      console.log(`[GraphQLClient] sendMutation finish: ${JSON.stringify({
        requestAt: startTick,
        responseAt: (new Date()).getTime(),
        processTime: (new Date()).getTime() - startTick
      })}`)

      const keys = Object.keys(data)
      return { data: keys && keys[0] ? data[keys[0]] : data }
    } catch (error) {
      console.log(`[GraphQLClient] sendMutation has error: ${error}`)
      return { error: buildExceptionResponse(error) }
    }
  }

  public sendQueryThrowError = async (
    token: string,
    schema: DocumentNode,
    variables: Record<string, any> = null
  ) => {
    const { data, error } = await this.sendQuery(token, schema, variables)
    if (error) throw error
    return data
  }

  public sendMutationThrowError = async (
    token: string,
    schema: DocumentNode,
    variables: Record<string, any> = null
  ) => {
    const { data, error } = await this.sendMutation(token, schema, variables)
    if (error) throw error
    return data
  }
}
