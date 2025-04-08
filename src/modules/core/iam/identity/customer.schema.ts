import * as GQLTag from 'graphql-tag'

export const CUSTOMER_RECOGNIZE = GQLTag.gql`
  mutation customerRecognize($arguments: CustomerArgs!) {
    customerRecognize(arguments: $arguments) {
      id
      username
      phones
      emails
      names
    }
  }
`

export const CUSTOMER_SEND_OTP = GQLTag.gql`
  mutation iamIdentityCustomerSendOTP($customerId: String!, $phone: String!) {
    iamIdentityCustomerSendOTP(
      arguments: { customerId: $customerId, phone: $phone }
    ) {
      customerId
      receivedPhone
      otp
      organization
    }
  }
`

export const CUSTOMER_SEND_SMS = GQLTag.gql`
  mutation iamIdentityCustomerSendSMS(
    $customerId: String!
    $phone: String!
    $message: String!
  ) {
    iamIdentityCustomerSendSMS(
      arguments: { customerId: $customerId, phone: $phone, message: $message }
    ) {
      customerId
      receivedPhone
      message
      organization
    }
  }
`

