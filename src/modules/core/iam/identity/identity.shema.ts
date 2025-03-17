import * as GQLTag from 'graphql-tag'

export const IdentitySchema = {
  PHONE_LOGIN: GQLTag.gql`
    mutation login(
      $phone: String!
      $password: String!
      $serviceId: String!
      $organizationId: String!
    ) {
      identityLogin(
        credential: {
          phone: $phone
          password: $password
          serviceId: $serviceId
          organizationId: $organizationId
        }
      ) {
        accessToken
        refreshToken
        loggedInTime
        user {
          id
          phone
          email
          username
          fullname
          dateOfBirth
          updatedAt
          avatar { id name location }
          bankAccount { id accountNumber accountHolder cardNumber bankName }
          profileVerified
          carriers { id name }
          address { id latitude longitude countryId provinceId districtId wardId country province district ward address }
          name
          taxNumber
          frontIdCard { id name location }
          backIdCard { id name location }
          images { id name location }
          desiredDistance
          businessRoles { id name code status }
        }
        avaiableBusinessRoles {
          id
          name
          code
          status
          agreementUrl
          contentUrl
        }
      }
    }`,
  PHONE_CHALLENGE: GQLTag.gql`
    mutation identityPhoneChallenge(
      $phone: String!
      $email: String
      $serviceId: String!
      $organizationId: String!
    ) {
      identityPhoneChallenge(
        arguments: {
          phone: $phone
          email: $email
          serviceId: $serviceId
          organizationId: $organizationId
        }
      ) {
        target
        session
        organization
      }
    }`,
  FIND_USER_BY_ID: GQLTag.gql`
    query identityFindUserById($userId: String!) {
      identityFindUserById(id: $userId) {
        id
        username
        fullname
        phone
        email
      }
    }`,
  FIND_SUBSCRIBED_USER: GQLTag.gql`
    query identitySubscribedUser($userId: String!) {
      identitySubscribedUser(userId: $userId) {
        id
        username
        fullname
        phone
        email
      }
    }`,
  IDENTITY_REGISTER: GQLTag.gql`
    mutation identityRegister(
      $name: String!
      $phone: String!
      $password: String!
      $serviceId: String!
      $organizationId: String!
    ) {
      identityRegister(
        arguments: {
          name: $name
          phone: $phone
          password: $password
          serviceId: $serviceId
          organizationId: $organizationId
        }
      ) {
        target
        session
        organization
      }
    }`,
  UPDATE_AVATAR: GQLTag.gql`
    mutation identityUpdateAvatar($fileId: String!) {
      identityUpdateAvatar(fileId: $fileId) {
        id
        fullname
        phone
        email
        dateOfBirth
        avatar {
          id
          location
          name
          size
        }
      }
    }`
}

export const IdentitySysSchema = {
  SYS_LOGIN: GQLTag.gql`
    mutation sysLogin(
      $email: String!
      $password: String!
      $serviceId: String!
      $organizationId: String!
    ) {
      identitySysLogin(
        credential: {
          email: $email
          password: $password
          serviceId: $serviceId
          organizationId: $organizationId
        }
      ) {
        accessToken
        refreshToken
        loggedInTime
        user {
          id
          phone
          email
          username
          fullname
          dateOfBirth
          updatedAt
          avatar { id name location }
          bankAccounts { id accountNumber accountHolder cardNumber bankName }
          carriers { id name }
          businessRoles { id name code status }
        }
      }
    }`,
  SYS_LOGOUT: GQLTag.gql`
    mutation {
      identitySysLogout {
        id
        username
        fullname
        phone
        email
      }
    }`,
  SYS_REFRESH_TOKEN: GQLTag.gql`
  mutation sysRefreshToken($token: String!) {
    identitySysRefreshToken(refreshToken: $token) {
      accessToken
      refreshToken
      user {
        id
        email
        fullname
        dateOfBirth
      }
    }
  }`,
  SYS_CHANGE_PASSWORD: GQLTag.gql`
  mutation iamIdentitySysChangePassword($arguments: ChangePasswordArgs!) {
    iamIdentitySysChangePassword(arguments: $arguments) {
      accessToken
      refreshToken
      loggedInTime
      user {
        id
        email
        fullname
        dateOfBirth
        avatar { id name location }
        businessRoles { id name code status agreementUrl contentUrl }
        updatedAt
      }
    }
  }`,
  SYS_USER_CREATE: GQLTag.gql`
  mutation sysUserCreate($arguments: SysUserCreateArgs!) {
    identitySysUserCreate(arguments: $arguments) {
      id
      phone
      phones
      email
      username
      fullname
      dateOfBirth
      address {
        id
        addressZoneId
        wardId
        districtId
        provinceId
        countryId
        latitude
        longitude
        address
        ward
        district
        province
        country
      }
      avatar { id location }
      businessRoles {
        id
        name
        code
        status
        agreementUrl
        contentUrl
        address {
          id
          addressZoneId
          wardId
          districtId
          provinceId
          countryId
          latitude
          longitude
          address
          ward
          district
          province
          country
        }
        bankAccount {
          id
          accountNumber
          accountHolder
          cardNumber
          bankBranch
          bankName
        }
      }
    }
  }`,
  SYS_USER_UPDATE: GQLTag.gql`
  mutation identitySysUserUpdate($arguments: SysUserUpdateArgs!) {
    identitySysUserUpdate(arguments: $arguments) {
      id
      phone
      phones
      email
      username
      fullname
      dateOfBirth
      updatedAt
      address {
        id
        addressZoneId
        wardId
        districtId
        provinceId
        countryId
        latitude
        longitude
        address
        ward
        district
        province
        country
      }
      avatar {
        id
        location
      }
      businessRoles {
        id
        name
        code
        status
        agreementUrl
        contentUrl
        address {
          id
          addressZoneId
          wardId
          districtId
          provinceId
          countryId
          latitude
          longitude
          address
          ward
          district
          province
          country
        }
        bankAccount {
          id
          accountNumber
          accountHolder
          cardNumber
          bankBranch
          bankName
        }
      }
    }
  }`,
  SYS_PROFILE: GQLTag.gql`
  query identitySysProfile {
    identitySysProfile {
      id
      type
      phone
      phones
      email
      username
      fullname
      dateOfBirth
      businessRoles {
        id
        name
        code
        status
        agreementUrl
        contentUrl
        address {
          address
          ward
          district
          province
          country
        }
        bankAccount {
          id
          accountNumber
          accountHolder
          cardNumber
          bankBranch
          bankName
        }
      }
      bankAccounts {
        id
        accountNumber
        accountHolder
        cardNumber
        bankBranch
        bankName
      }
      carriers {
        id
        name
      }
      avatar {
        id
        name
        location
      }
      address {
        address
        ward
        district
        province
        country
      }
      sessionBusinessRole {
        id
        name
        code
        status
        agreementUrl
        contentUrl
        address {
          address
          ward
          district
          province
          country
        }
        bankAccount {
          id
          accountNumber
          accountHolder
          cardNumber
          bankBranch
          bankName
        }
      }
      sessionMultiBusinessRoles {
        id
        name
        code
        status
        agreementUrl
        contentUrl
        address {
          address
          ward
          district
          province
          country
        }
        bankAccount {
          id
          accountNumber
          accountHolder
          cardNumber
          bankBranch
          bankName
        }
      }
      unreadNotificationCount
      configuration {
        menu {
          items {
            id
            name
            code
            description
            metadata
            childs {
              id
              name
              code
              description
              metadata
            }
          }
          description
        }
      }
    }
  }`,
  SYS_SET_PASSWORD: GQLTag.gql`
  mutation identitySysUserSetPassword($arguments: SysUserSetPasswordArgs!){
    identitySysUserSetPassword(arguments: $arguments) {
      id
      username
    }
  }`,
  FIND_BANK_BY_ID: GQLTag.gql`
    query identityBankGetDetail($id: String!) {
      identityBankGetDetail(id: $id) {
        id
        type
        vn_name
        en_name
        brandName
        swiffCode
      }
    }`,
  FIND_BANK_BY_NAME: GQLTag.gql`
    query identityBankGetDetailByName($name: String!) {
      identityBankGetDetailByName(name: $name) {
        id
        type
        vn_name
        en_name
        brandName
        swiffCode
      }
    }`,
  USER_CREATE: GQLTag.gql`
  mutation identityCreateUser($arguments: CreateUserArgs!) {
    identityCreateUser(arguments: $arguments) {
      id
      email
      fullname
      phone
      dateOfBirth
      avatar { id name location }
      createdAt
      updatedAt
    }
  }`,
  USER_PROFILE: GQLTag.gql`
  query identityProfile {
    identityProfile {
      id
      phone
      phones
      email
      username
      fullname
      name
      unreadNotificationCount
    }
  }`,
  USER_PROFILE_WITH_REQUEST_ID: GQLTag.gql`
  query identityProfile($requestId: String) {
    identityProfile(requestId: $requestId) {
      id
      phone
      phones
      email
      username
      fullname
      name
      unreadNotificationCount
    }
  }`,
  REMOVE_USER_TOKEN_BY_SECRET: GQLTag.gql`
    mutation deleteSessionTokenUserInActive($arguments: RemoveSessionArgs!) {
      identitySystemRemoveSessions(arguments: $arguments) {
        totalCount
      }
    }`,
  REMOVE_TOKEN: GQLTag.gql`
    mutation identityRemoveSessions($arguments: RemoveSessionArgs!) {
      identityRemoveSessions(arguments: $arguments) {
        totalCount
      }
    }`
}