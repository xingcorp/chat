import { forwardRef, Inject, Injectable } from '@nestjs/common'
import { IAMGraphQlClient } from '../iam.client'
import { Request } from 'express'
import * as GQLTag from 'graphql-tag'

const GET_PERMISSION = GQLTag.gql`
  query accessGetPermission($serviceCode: String!) {
    accessGetPermission(serviceCode: $serviceCode) {
      version
      serviceCode
      isRoot
      statement {
        Allow {
          service
          effect
          actions
          resources
          condition
        }
        Deny {
          service
          effect
          actions
          resources
          condition
        }
      }
      userInfo {
        userId
        businessRoleId
        organizationId
        user {
          id
          username
          phone
          email
        }
        organization {
          id
          name
          type
          code
          phone
          owner {
            id
            phone
          }
        }
        businessRole {
          id
          name
          code
        }
      }
    }
  }
`

@Injectable()
export class AccessService {
  constructor(
    @Inject(forwardRef(() => IAMGraphQlClient))
    private readonly iamClient: IAMGraphQlClient
  ) { }

  public async forwardRequest(request: Request) {
    return await this.iamClient.forwardRequest(request)
  }

  public async getPermission(token) {
    return this.iamClient.sendMutation(
      token,
      GET_PERMISSION, {
      serviceCode: process.env.SERVICE_CODE
    }
    )
  }
}
