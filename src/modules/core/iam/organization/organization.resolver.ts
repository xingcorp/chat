import { Args, Query, Resolver } from '@nestjs/graphql'
import { Request } from 'express'
import {
  BearerAccessToken,
  CurrentRequest
} from '../../middleware/decorator/request.decorator'
import { Organization } from '../objects/organization'
import { OrganizationResponse } from './organization.response'
import { OrganizationService } from './organization.service'
import { OrganizationFilter } from './organization.arg'
import { SetMetadata } from '@nestjs/common'
import { ServiceActions, ServiceKeys } from '../../middleware/guard/service.action'

export enum OrganizationType {
  Group = 'Group',
  Company = 'Company',
  Distributor = 'Distributor',
  Shop = 'Shop',
  Sale = 'Sale',
  SSale = 'SSale',
  PGSale = 'PGSale',
  PGGTSale = 'PGGTSale',
  Telesale = 'Telesale',
  QualityControl = 'QualityControl',
  Invidiual = 'Invidiual',
  Unknow = 'Unknow'
}
@Resolver()
export class OrganizationResolver {
  constructor (private readonly organizationService: OrganizationService) { }

  @Query(() => OrganizationResponse, { name: 'organizationGetGroup' })
  async getGroup(
    @BearerAccessToken() token: string
  ): Promise<OrganizationResponse> {
    const { data, error } = await this.organizationService.getGroup(token)

    if (error) {
      console.log('[OrganizationResolver] getGroup has error: ', error)
    }

    const result = []
    if (data && data.organizations) {
      data.organizations.map((org) => {
        if (org.id === process.env.OFFICE_ORGANIZATION_ID) {
          result.push(org)
        }
      })
    }

    return {
      total: result.length,
      count: result.length,
      organizations: result
    }
  }

  @Query(() => OrganizationResponse, { name: 'organizationGetList' })
  async getList(
    @CurrentRequest() request: Request
  ): Promise<OrganizationResponse> {
    return await this.organizationService.forwardRequest(request)
  }

  @Query(() => Organization, { name: 'organizationGetByCode' })
  async getByCode(
    @Args('code', { nullable: false }) _code: string,
    @CurrentRequest() request: Request
  ): Promise<Organization> {
    return await this.organizationService.forwardRequest(request)
  }

  @Query(() => OrganizationResponse, { name: 'organizationGetByPhone' })
  async getByPhone(
    @Args('phone', { nullable: false }) _phone: string,
    @CurrentRequest() request: Request
  ): Promise<OrganizationResponse> {
    return await this.organizationService.forwardRequest(request)
  }

  @Query(() => OrganizationResponse, { name: 'steamGetListSale' })
  @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
  async getListSale(
    @Args('filter', { nullable: true }) filter: OrganizationFilter,
    @BearerAccessToken() token: string
  ): Promise<OrganizationResponse> {
    filter.parentId = process.env.STEAM_ORGANIZATION_ID
    filter.type = OrganizationType.SSale
    return this.organizationService.getListSaleSteam(token, filter)
  }
}
