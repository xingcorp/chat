import { forwardRef, Inject, Injectable } from '@nestjs/common'
import { FactoryGraphQlClient } from './factory.client'
import * as GQLTag from 'graphql-tag'
import { Request } from 'express'

const ProductTypeSchema = {
  PRODUCT_TYPE_GET_BY_ID_QUERY: GQLTag.gql`
  query productGetTypeById($id: String!) {
    productGetTypeById(id: $id) {
      id
      name
      code
      price
      model
      productCategory { id name code brandName brand {id code name } }
    }
  }`,
  PRODUCT_TYPE_GET_LIST_QUERY: GQLTag.gql`
  query productGetTypes($filter: ProductTypeFilter) {
    productGetTypes(filter: $filter) {
      total
      count
      productTypes {
        id
        name
        code
        price
        model
        warrantyMonths
        factoryWarrantyMonths
        productCategory { id name code brandName brand {id code name } }
      }
    }
  }`,
  PRODUCT_CATEGORY_GET_LIST_QUERY: GQLTag.gql`
  query productGetCategories {
    productGetCategories {
      total
      count
      productCategories {
        id
        name
        code
        brand { id name code }
      }
    }
  }`,
  PRODUCT_BRAND_GET_LIST_QUERY: GQLTag.gql`
  query productGetBrands {
    productGetBrands {
      total
      count
      productBrands { id name code }
    }
  }`,
  PRODUCT_TYPE_SYNCHRONIZE_QUERY: GQLTag.gql`
  query factoryProductTypeSynchronize($filter: ProductTypeSynchronizeFilter!) {
    factoryProductTypeSynchronize(filter: $filter) {
      total
      count
      productTypes {
        id
        name
        code
        price
        model
        warrantyMonths
        factoryWarrantyMonths
        stampType
        productCategory { 
          id 
          name 
          code
          brand {
            id 
            code 
            name 
            updatedAt 
            deletedAt 
          } 
          updatedAt 
          deletedAt 
        }
        updatedAt
        deletedAt 
      }
    }
  }`
}


@Injectable()
export class FactoryService {
  constructor(
    @Inject(forwardRef(() => FactoryGraphQlClient))
    private readonly factoryClient: FactoryGraphQlClient
  ) { }

  public async forwardRequest(request: Request) {
    return await this.factoryClient.forwardRequest(request)
  }

  public productTypeFindById(bearerToken: string, value: string) {
    return this.factoryClient.sendQuery(
      bearerToken,
      ProductTypeSchema.PRODUCT_TYPE_GET_BY_ID_QUERY,
      { id: value }
    )
  }

  public productTypeFindByFilter(bearerToken: string, filter: Record<string, any>) {
    return this.factoryClient.sendQuery(
      bearerToken,
      ProductTypeSchema.PRODUCT_TYPE_GET_LIST_QUERY,
      { filter }
    )
  }

  public productCategoryFindByFilter(bearerToken: string, filter: Record<string, any>) {
    return this.factoryClient.sendQuery(
      bearerToken,
      ProductTypeSchema.PRODUCT_CATEGORY_GET_LIST_QUERY
    )
  }

  public productBrandFindByFilter(bearerToken: string, filter: Record<string, any>) {
    return this.factoryClient.sendQuery(
      bearerToken,
      ProductTypeSchema.PRODUCT_BRAND_GET_LIST_QUERY
    )
  }

  public productTypeSynchronize(bearerToken: string, filter: Record<string, any>) {
    return this.factoryClient.sendQuery(
      bearerToken,
      ProductTypeSchema.PRODUCT_TYPE_SYNCHRONIZE_QUERY,
      { filter }
    )
  }
}
