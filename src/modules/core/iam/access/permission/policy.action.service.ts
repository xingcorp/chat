import { forwardRef, Inject, Injectable } from "@nestjs/common"
import * as GQLTag from 'graphql-tag'
import { PolicyAction } from "../../objects/policy.action"
import { IAMGraphQlClient } from "../../iam.client"

export const PolicyActionSchema = {
    POLICY_ACTION_LIST_QUERY: GQLTag.gql`
    query iamAccessPolicyActionGetList($filter: PolicyActionFilterArgs!){
        iamAccessPolicyActionGetList(filter: $filter) {
            total
            count
            actions {
                id
                name
                code
                parent { id name code }
                children { id name code }
            }
        }
    }`
}

export interface IPolicyActionResponse {
    total: number,
    count: number,
    actions: PolicyAction[]
}

@Injectable()
export class IAMPolicyActionService {
    constructor(
        @Inject(forwardRef(() => IAMGraphQlClient))
        private readonly iamClient: IAMGraphQlClient
    ) { }

    public async list(bearerToken: string, filter: Record<string, any>) {
        return await this.iamClient.sendQueryThrowError(
            bearerToken,
            PolicyActionSchema.POLICY_ACTION_LIST_QUERY,
            { filter: filter }
        )
    }

}