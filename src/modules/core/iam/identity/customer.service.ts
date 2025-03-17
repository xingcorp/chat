import { Injectable } from "@nestjs/common"
import { GraphQLClient } from "../../common/graphql.client"
import { CUSTOMER_RECOGNIZE, CUSTOMER_SEND_OTP, CUSTOMER_SEND_SMS } from "./customer.schema"

@Injectable()
export class CustomerService extends GraphQLClient {
    constructor() {
        super(process.env.SRT_IAM_MICROSERVICE_DOMAIN)
    }

    public recognizeCustomer = async (
        bearerToken,
        info
    ) => {
        return this.sendMutation(bearerToken,
            CUSTOMER_RECOGNIZE,
            { arguments: info }
        )
    }

    public sendOtp = async (
        bearToken: string,
        customerId: string,
        phone: string
    ) => {
        return this.sendMutation(
            bearToken,
            CUSTOMER_SEND_OTP,
            {
                customerId: customerId,
                phone: phone
            }
        )
    }

    public sendSms = async (
        bearToken: string,
        customerId: string,
        phone: string,
        message: string
    ) => {
        return this.sendMutation(
            bearToken,
            CUSTOMER_SEND_SMS,
            {
                customerId: customerId,
                phone: phone,
                message: message
            }
        )
    }
}