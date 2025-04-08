import { Injectable } from "@nestjs/common"
import { GraphQLClient } from "../common/graphql.client"
import * as GQLTag from 'graphql-tag'

const ACCESS_GRANTED_QUERY = GQLTag.gql`
  query iamAccessGranted($arguments: AccessGrantedArgs!) {
    iamAccessGranted(arguments: $arguments) {
      version
      serviceCode
      isRoot
      granted
      userInfo {
        userId
        organizationId
        businessRoleIds
        user { id username phone email type }
        organization {
          id
          name
          type
          code
          phone
          owner { id phone }
        }
        businessRoles { id name code status }
      }
    }
  }`

@Injectable()
export class IAMGraphQlClient extends GraphQLClient {
  constructor() {
    super(process.env.SRT_IAM_MICROSERVICE_DOMAIN)
  }

  public async getPermission(
    token: string,
    actions: string[],
    resources: string[] = null,
    conditions: string = null
  ) {
    const args: Record<string, any> = { actions }
    if (resources) { args.resources = resources }
    if (conditions) { args.conditions = conditions }
    return this.sendMutation(token, ACCESS_GRANTED_QUERY, { arguments: args })
  }
}