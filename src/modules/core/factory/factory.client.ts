import { Injectable } from "@nestjs/common"
import { GraphQLClient } from "../common/graphql.client"

@Injectable()
export class FactoryGraphQlClient extends GraphQLClient {
    constructor() {
        super(process.env.SRT_FACTORY_MICROSERVICE_DOMAIN)
    }
}