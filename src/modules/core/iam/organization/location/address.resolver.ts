import { Inject, forwardRef } from '@nestjs/common'
import { Args, Field, Float, InputType, Int, Query, Resolver } from '@nestjs/graphql'
import { Request } from 'express'
import { CurrentRequest } from '../../../middleware/decorator/request.decorator'
import { AddressResponse, AddressZoneResponse, LocationResponse } from './address.response'
import { AddressService } from './address.service'
import { AddressTextArgs, LocationArgs } from './address.args'

@InputType()
export class AddressZoneFilterArgs {
  @Field(() => Int, { nullable: true, defaultValue: 0 })
  page?: number

  @Field(() => Int, { nullable: true, defaultValue: 100 })
  size?: number

  @Field(() => String, { nullable: true })
  parentId: string

  @Field(() => String, { nullable: true })
  keyword: string

  @Field(() => Float, { nullable: true })
  updatedAt: number
}


@Resolver()
export class AddressResolver {
  constructor(
    @Inject(forwardRef(() => AddressService))
    private readonly addressService: AddressService
  ) { }

  @Query(() => AddressZoneResponse, { name: 'addressZoneGetList' })
  async zoneList(
    @Args('filter', { nullable: true }) _filter: AddressZoneFilterArgs,
    @CurrentRequest() request: Request
  ): Promise<AddressZoneResponse> {
    return this.addressService.forwardRequest(request)
  }

  @Query(() => AddressZoneResponse, { name: 'addressGetCountries' })
  async addressGetCountries(
    @Args('keyword', { nullable: true }) _keyword: string,
    @Args('filter', { nullable: true }) _filter: AddressZoneFilterArgs,
    @CurrentRequest() request: Request
  ): Promise<AddressZoneResponse> {
    return this.addressService.forwardRequest(request)
  }

  @Query(() => AddressZoneResponse, { name: 'addressGetProvinces' })
  async addressGetProvinces(
    @Args('countryId', { nullable: true }) _countryId: string,
    @Args('keyword', { nullable: true }) _keyword: string,
    @Args('filter', { nullable: true }) _filter: AddressZoneFilterArgs,
    @CurrentRequest() request: Request
  ): Promise<AddressZoneResponse> {
    return this.addressService.forwardRequest(request)
  }

  @Query(() => AddressZoneResponse, { name: 'addressGetDistricts' })
  async addressGetDistricts(
    @Args('provinceId', { nullable: true }) _provinceId: string,
    @Args('keyword', { nullable: true }) _keyword: string,
    @Args('filter', { nullable: true }) _filter: AddressZoneFilterArgs,
    @CurrentRequest() request: Request
  ): Promise<AddressZoneResponse> {
    return this.addressService.forwardRequest(request)
  }

  @Query(() => AddressZoneResponse, { name: 'addressGetWards' })
  async addressGetWards(
    @Args('districtId', { nullable: false }) _districtId: string,
    @Args('keyword', { nullable: true }) _keyword: string,
    @Args('filter', { nullable: true }) _filter: AddressZoneFilterArgs,
    @CurrentRequest() request: Request
  ): Promise<AddressZoneResponse> {
    return this.addressService.forwardRequest(request)
  }

  @Query(_return => AddressResponse, { name: "addressGetZoneByLocation" })
  async addressGetZoneByLocation(
    @Args("params") _params: LocationArgs,
    @CurrentRequest() request: Request
  ) {
    return this.addressService.forwardRequest(request)
  }

  @Query(_return => LocationResponse, { name: "addressGetLocationByText" })
  async addressGetLocationByText(
    @Args("params") _params: AddressTextArgs,
    @CurrentRequest() request: Request
  ) {
    return this.addressService.forwardRequest(request)
  }
}
