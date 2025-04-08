import { Injectable } from '@nestjs/common'
import * as GQLTag from 'graphql-tag'
import { GraphQLClient } from 'src/modules/core/common/graphql.client'
import { AddressLevel, AddressZone } from '../../objects/address.zone'
import { LocationArgs, ZoneNameArgs } from './address.args'

const AddressSchema = {
  ADDRESS_ZONE_GET_LIST: GQLTag.gql`
  query addressZoneGetList($filter: AddressZoneFilterArgs!){
    addressZoneGetList(filter: $filter) {
      total
      count
      zones {
        id
        code
        name
        level
        parent {
          id
          code
          name
          level
          parent {
            id
            code
            name
            level
            parent {
              id
              code
              name
              level
            }
          }
        }
      }
    }
  }`,
  ADDRESS_GET_DETAIL: GQLTag.gql`
  query addressGetDetail($id: String!) {
    addressGetDetail(id: $id) {
      id
      latitude
      longitude
      address
      country
      province
      district
      ward
      ownerId
    }
  }`,
  ADDRESS_ZONE_GET_DETAIL: GQLTag.gql`
  query addressGetZoneDetail($id: String!) {
    addressGetZoneDetail(id: $id) {
      id
      code
      name
      level
      parent {
        id
        code
        name
        level
        parent {
          id
          code
          name
          level
          parent {
            id
            code
            name
            level
          }
        }
      }
    }
  }`,
  ADDRESS_ZONE_GET_DETAIL_BY_NAME: GQLTag.gql`
  query addressGetZoneByDetailName($params: ZoneNameArgs!) {
    addressGetZoneByDetailName(params: $params) {
      id
      code
      name
      level
      parent {
        id
        code
        name
        level
        parent {
          id
          code
          name
          level
          parent {
            id
            code
            name
            level
          }
        }
      }
    }
  }`,
  ADDRESS_ZONE_GET_DISTRICTS: GQLTag.gql`
  query addressGetDistricts($filter: AddressZoneFilterArgs!) {
    addressGetDistricts(filter: $filter) {
      total
      count
      zones {
        id
        code
        name
        level
        updatedAt
        parent {
          id
          code
          name
          level
          updatedAt
          parent {
            id
            code
            name
            level
            updatedAt
          }
        }
      }
    }
  }`,
  ADDRESS_ZONE_FIND_BY_NAMES: GQLTag.gql`
  query addressZoneFindByNames($province: String!, $district: String!, $ward: String!) {
    addressZoneFindByNames(province: $province, district: $district, ward: $ward) {
      id
      code
      name
      fullname
    }
  }`,
  ADDRESS_ZONE_FIND_BY_NAME: GQLTag.gql`
  query addressZoneFindByName($arguments: AddressFindZoneArgs!) {
    addressZoneFindByName(arguments: $arguments) {
      id
      name
      code
      fullname
      english
      level
    }
  }`,
  GET_ZONE_BY_LOCATION: GQLTag.gql`
  query AddressGetZoneByLocation($params: LocationArgs!) {
    addressGetZoneByLocation(params: $params) {
        fullAddress
        address
        province
        district
        ward
        addressZone {
          id
          level
          code
          name
          fullname
          english
          parent {
              id
              level
              code
              name
              fullname
              english
              parent {
                  id
                  level
                  code
                  name
                  fullname
                  english
              }
          }
      }
    }
  }`,
}

@Injectable()
export class AddressService extends GraphQLClient {
  constructor () {
    super(process.env.SRT_IAM_MICROSERVICE_DOMAIN)
  }

  public async addressZoneFindById(
    bearerToken: string,
    zoneId: string
  ) {
    return await this.sendQueryThrowError(
      bearerToken,
      AddressSchema.ADDRESS_ZONE_GET_DETAIL,
      { id: zoneId }
    )
  }

  public async addressZoneFindByDetailName(
    bearerToken: string,
    args: ZoneNameArgs
  ) {
    return await this.sendQueryThrowError(
      bearerToken,
      AddressSchema.ADDRESS_ZONE_GET_DETAIL_BY_NAME,
      { params: args }
    )
  }

  public async addressFindById(
    bearerToken: string,
    addressId: string
  ) {
    return await this.sendQueryThrowError(
      bearerToken,
      AddressSchema.ADDRESS_GET_DETAIL,
      { id: addressId }
    )
  }

  public async addressGetDistricts(
    bearerToken: string,
    page: number,
    size: number,
    keyword: string = null,
    updatedAt: number = 0
  ) {
    const filter: any = {}
    if (page) { filter.page = page }
    if (size) { filter.size = size }
    if (keyword) { filter.keyword = keyword }
    if (updatedAt > 0) { filter.updatedAt = updatedAt }

    return await this.sendQueryThrowError(
      bearerToken,
      AddressSchema.ADDRESS_ZONE_GET_DISTRICTS,
      { filter: filter }
    )
  }

  public async addressZoneFindByNames(
    bearerToken: string,
    province: string,
    district: string,
    ward: string
  ) {
    return await this.sendQueryThrowError(
      bearerToken,
      AddressSchema.ADDRESS_ZONE_FIND_BY_NAMES,
      {
        province,
        district,
        ward
      }
    )
  }

  public async zoneFindByIds(
    bearerToken: string,
    ids: string[]
  ): Promise<AddressZone[]> {
    const { data, error } = await this.sendQuery(
      bearerToken,
      AddressSchema.ADDRESS_ZONE_GET_LIST,
      { filter: { zoneIds: ids } }
    )

    if (error) {
      console.log('[AddressService] get zone list has error: ', error)
      return []
    }

    return data.zones ? data.zones : []
  }

  public async zoneFindName(
    token: string,
    name: string,
    level: AddressLevel
  ): Promise<AddressZone> {
    const { data, error } = await this.sendQuery(
      token,
      AddressSchema.ADDRESS_ZONE_FIND_BY_NAME,
      { arguments: { name, level } }
    )

    if (error) {
      console.log('[AddressService] zone find by name has error: ', error)
      return null
    }

    return data
  }

  public async getZoneByLocation(bearerToken: string, params: LocationArgs) {
    const { data, error } = await this.sendQuery(
      bearerToken,
      AddressSchema.GET_ZONE_BY_LOCATION,
      { params: { ...params } }
    )

    if (error) {
      console.log('[AddressService] zone find by location has error: ', error)
      return null
    }

    return data
  }
}
