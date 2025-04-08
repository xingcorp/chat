import * as GQLTag from 'graphql-tag'

export const OrganizationSchema = {
  GET_ORGANIZATION_DETAIL: GQLTag.gql`
  query organizationGetDetail($id: String!) {
    organizationGetDetail(organizationId: $id) {
      id
      name
      type
      code
      pdaCode
      name
      distributorChanel
      salesOffice
      phone
      region
      regionCode
      area
      address {
        country
        province
        district
        ward
        address
        longitude
        latitude
      }
      ownerId
      owner {
        id
        phone
        email
        fullname
      }
    }
  }`,
  ORGANIZATION_GET_BY_PHONE: GQLTag.gql`
  query organizationGetByPhone($phone: String!) {
    organizationGetByPhone(phone: $phone) {
      id
      name
      type
      code
      pdaCode
      name
      distributorChanel
      salesOffice
      phone
      region
      regionCode
      area
      address {
        country
        province
        district
        ward
        address
        longitude
        latitude
      }
    }
  }`,
  ORGANIZATION_GET_BY_OWNER_ID: GQLTag.gql`
  query organizationGetByOwner($ownerId: String!) {
    organizationGetByOwner(ownerId: $ownerId) {
      id
      name
      type
      code
      pdaCode
      name
      distributorChanel
      salesOffice
      phone
      region
      regionCode
      area
      address {
        country
        province
        district
        ward
        address
        longitude
        latitude
      }
    }
  }`,
  ORGANIZATION_GET_GROUP: GQLTag.gql`
  query organizationGetGroup {
    organizationGetGroup {
      total
      count
      organizations {
        id
        code
        name
      }
    }
  }`,
  ORGANIZATION_GET_LIST_SALE_STEAM: GQLTag.gql`
  query IamSteamOrganizationGetList($filter: OrganizationFilter) {
    iamSteamOrganizationGetList(
        filter: $filter
    ) {
        total
        count
        organizations {
            id
            createdAt
            updatedAt
            deletedAt
            type
            code
            pdaCode
            name
            distributorChanel
            salesOffice
            phone
            email
            region
            regionCode
            area
            ownerId
            kshopOrgId
            identityCardNo
            idCardImages
            selfieImages
            jobPositions
            status
            orgEmail
            isPartner
            owner {
              id
              email
              address {
                address
                country
                countryId
                createdAt
                district
                districtId
                id
                latitude
                longitude
                province
                provinceId
                updatedAt
                ward
                wardId
            }
          }
        }
    }
  }`,
}