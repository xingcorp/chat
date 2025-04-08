import * as GQLTag from 'graphql-tag'

export const BusinessRoleSchema = {
    GET_BUSINESS_FIND_BY_ID: GQLTag.gql`
    query iamBusinessRoleFindById($id: String!) {
        iamBusinessRoleFindById(id: $id) {
            id
            type
            code
            name
            status
            agreementUrl
            contentUrl
            organization { id name }
            address {
                id
                latitude
                longitude
                country
                province
                district
                ward
                address
                countryId
                provinceId
                districtId
                wardId
                addressZoneId
            }
        }
    }`,
    GET_BUSINESS_FIND_BY_CODE: GQLTag.gql`
    query iamBusinessRoleFindByCode($code: String!) {
        iamBusinessRoleFindByCode(code: $code) {
            id
            type
            code
            name
            status
            agreementUrl
            contentUrl
            organization { id name }
            address {
                id
                latitude
                longitude
                country
                province
                district
                ward
                address
                countryId
                provinceId
                districtId
                wardId
                addressZoneId
            }
        }
    }`,
    GET_BUSINESS_FIND_BY_NAME: GQLTag.gql`
    query iamBusinessRoleFindByName($name: String!) {
        iamBusinessRoleFindByName(name: $name) {
            id
            type
            code
            name
            status
            agreementUrl
            contentUrl
            organization { id name }
            address {
                id
                latitude
                longitude
                country
                province
                district
                ward
                address
                countryId
                provinceId
                districtId
                wardId
                addressZoneId
            }
        }
    }`,
    GET_BUSINESS_FIND_BY_CODES: GQLTag.gql`
    query iamBusinessRoleFindByCodes($codes: [String!]!) {
        iamBusinessRoleFindByCodes(codes: $codes) {
            total
            count
            businessRoles {
                id
                type
                code
                name
                status
                agreementUrl
                contentUrl
                organization { id name }
                address {
                    id
                    latitude
                    longitude
                    country
                    province
                    district
                    ward
                    address
                    countryId
                    provinceId
                    districtId
                    wardId
                    addressZoneId
                }
            }
        }
    }`,
    GET_BUSINESS_USERS_BY_CODE: GQLTag.gql`
    query iamBusinessRoleGetUsersByCode($arguments: BusinessRoleGetUsersByCodeArgs!) {
        iamBusinessRoleGetUsersByCode(arguments: $arguments) {
            total
            count
            users {
                id
                type
                fullname
                phone
                phones
                email
                updatedAt
                deletedAt
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
                    type
                    code
                    name
                    status
                    agreementUrl
                    contentUrl
                    organization { id name }
                    address {
                        id
                        latitude
                        longitude
                        country
                        province
                        district
                        ward
                        address
                        countryId
                        provinceId
                        districtId
                        wardId
                        addressZoneId
                    }
                }
            }
        }
    }`,
    GET_BUSINESS_ROLE_LIST: GQLTag.gql`
    query iamBusinessRoleGetList($filter: BusinessRoleFilterArgs) {
        iamBusinessRoleGetList(filter: $filter) {
            total
            count
            businessRoles {
                id
                type
                code
                name
                agreementUrl
                contentUrl
                organization { id name }
                policies {
                    id
                    service { id name code }
                    effect { id name code }
                    actions { 
                        id name code
                        parent { id name code }
                        children { id name code }
                    }
                }
            }
        }
    }`,
    GET_BUSINESS_ROLE_CMS_LIST: GQLTag.gql`
    query iamBusinessRoleCmsGetList($filter: BusinessRoleFilterArgs) {
        iamBusinessRoleCmsGetList(filter: $filter) {
            total
            count
            businessRoles {
                id
                type
                code
                name
                agreementUrl
                contentUrl
                organization { id name }
                policies {
                    id
                    service { id name code }
                    effect { id name code }
                    actions { 
                        id name code
                        parent { id name code }
                        children { id name code }
                    }
                }
            }
        }
    }`,
    GET_BUSINESS_ROLE_TOTAL_LIST: GQLTag.gql`
    query iamBusinessRoleGetList {
        iamBusinessRoleGetList(filter: { type: "CMS" }) {
            total
            count
        }
    }`,
    BUSSINESS_ROLE_ADD_USERS: GQLTag.gql`
    mutation iamBusinessRoleAddUsersToRole($arguments: BusinessRoleAddUsersToRoleArgs!) {
        iamBusinessRoleAddUsersToRole(arguments: $arguments) {
            total
            count
            users {
                id
                type
                fullname
                phone
                phones
                email
                updatedAt
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
                    type
                    code
                    name
                    status
                    agreementUrl
                    contentUrl
                    organization { id name }
                    address {
                        id
                        latitude
                        longitude
                        country
                        province
                        district
                        ward
                        address
                        countryId
                        provinceId
                        districtId
                        wardId
                        addressZoneId
                    }
                }
            }
        }
    }`,
    BUSSINESS_ROLE_REMOVE_USERS: GQLTag.gql`
    mutation iamBusinessRoleRemoveUsersToRole($arguments: BusinessRoleRemoveUsersToRoleArgs!) {
        iamBusinessRoleRemoveUsersToRole(arguments: $arguments) {
            total
            count
            users {
                id
                type
                fullname
                phone
                phones
                email
                updatedAt
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
                    code
                    name
                    status
                    agreementUrl
                    contentUrl
                    organization { id name }
                    address {
                        id
                        latitude
                        longitude
                        country
                        province
                        district
                        ward
                        address
                        countryId
                        provinceId
                        districtId
                        wardId
                        addressZoneId
                    }
                }
            }
        }
    }`,
    BUSSINESS_ROLE_APPROVE_USERS: GQLTag.gql`
    mutation iamBusinessRoleApprove($arguments: BusinessRoleApprovalArgs!) {
        iamBusinessRoleApprove(arguments: $arguments) {
            total
            count
            users {
                id
                type
                fullname
                phone
                phones
                email
                updatedAt
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
                    type
                    code
                    name
                    status
                    agreementUrl
                    contentUrl
                    organization { id name }
                    address {
                        id
                        latitude
                        longitude
                        country
                        province
                        district
                        ward
                        address
                        countryId
                        provinceId
                        districtId
                        wardId
                        addressZoneId
                    }
                }
            }
        }
    }`,
    BUSSINESS_ROLE_REJECT_USERS: GQLTag.gql`
    mutation iamBusinessRoleReject($arguments: BusinessRoleApprovalArgs!) {
        iamBusinessRoleReject(arguments: $arguments) {
            total
            count
            users {
                id
                type
                username
                fullname
                phone
                phones
                email
                updatedAt
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
                    type
                    code
                    name
                    status
                    agreementUrl
                    contentUrl
                    organization { id name }
                    address {
                        id
                        latitude
                        longitude
                        country
                        province
                        district
                        ward
                        address
                        countryId
                        provinceId
                        districtId
                        wardId
                        addressZoneId
                    }
                }
            }
        }
    }`,
    BUSSINESS_ROLE_SUSPEND_USERS: GQLTag.gql`
    mutation iamBusinessRoleSuspend($arguments: BusinessRoleApprovalArgs!) {
        iamBusinessRoleSuspend(arguments: $arguments) {
            total
            count
            users {
                id
                type
                fullname
                phone
                email
                updatedAt
                businessRoles {
                    id
                    type
                    code
                    name
                    status
                    agreementUrl
                    contentUrl
                    organization { id name }
                    address {
                        id
                        latitude
                        longitude
                        country
                        province
                        district
                        ward
                        address
                        countryId
                        provinceId
                        districtId
                        wardId
                        addressZoneId
                    }
                }
            }
        }
    }`,
    BUSSINESS_ROLE_USER_LIST_QUERY: GQLTag.gql`
    query iamBusinessRoleUserList($filter: BusinessRoleUserFilter!) {
        iamBusinessRoleUserList(filter: $filter) {
            total
            count
            businessRoles {
                id
                type
                code
                name
                status
                agreementUrl
                contentUrl
                organization { id name }
                address {
                    id
                    latitude
                    longitude
                    country
                    province
                    district
                    ward
                    address
                    countryId
                    provinceId
                    districtId
                    wardId
                    addressZoneId
                }
            }
        }
    }`,
    BUSINESS_ROLE_UPDATE: GQLTag.gql`
        mutation iamBusinessRoleUpdate($arguments: BusinessRoleUpdateArgs!) {
        iamBusinessRoleUpdate(arguments: $arguments) {
            id
            type
            code
            name
            description
            agreementUrl
            contentUrl
            organization { id name }
            policies {
                id
                service { id name code }
                effect { id name code }
                actions {
                    id
                    name
                    code
                    parent { id name code }
                    children { id name code }
                }
            }
        }
    }`,
    BUSINESS_ROLE_CREATE: GQLTag.gql`
        mutation iamBusinessRoleCreate($arguments: BusinessRoleCreateArgs!) {
        iamBusinessRoleCreate(arguments: $arguments) {
            id
            type
            code
            name
            description
            agreementUrl
            contentUrl
            organization { id name }
            policies {
                id
                service { id name code }
                effect { id name code }
                actions {
                    id
                    name
                    code
                    parent { id name code }
                    children { id name code }
                }
            }
        }
    }`
}
