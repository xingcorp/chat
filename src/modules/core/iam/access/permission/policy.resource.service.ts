import { Injectable } from "@nestjs/common"
import { GraphQLClient } from "src/modules/core/common/graphql.client"

@Injectable()
export class IAMPolicyResourceService extends GraphQLClient {
    constructor() {
        super(process.env.SRT_IAM_MICROSERVICE_DOMAIN)
    }

}