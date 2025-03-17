import { Args, Mutation, Query, Resolver } from "@nestjs/graphql"
import { Request } from 'express'
import { CurrentRequest } from "../middleware/decorator/request.decorator"
import {
    ProductBrandArgs,
    ProductBrandFilter,
    ProductCategoryArgs,
    ProductCategoryFilter,
    ProductTypeArgs,
    ProductTypeFilter
} from "./factory.args"
import {
    ProductBrandResponse,
    ProductCategoryResponse,
    ProductTypeResponse
} from "./factory.response"
import { FactoryService } from "./factory.service"
import { ProductBrand } from "./objects/product.brand"
import { ProductCategory } from "./objects/product.category"
import { ProductType } from "./objects/product.type"

@Resolver()
export class FactoryResolver {
    constructor(
        private readonly factoryService: FactoryService
    ) { }

    @Query(_return => ProductBrandResponse, { name: 'productGetBrands' })
    async productGetBrands(
        @Args('filter', { nullable: true }) _filter: ProductBrandFilter,
        @CurrentRequest() request: Request
    ): Promise<ProductBrandResponse> {
        return this.factoryService.forwardRequest(request)
    }

    @Query(_return => ProductCategoryResponse, { name: 'productGetCatgories' })
    async productGetCategories(
        @Args('filter', { nullable: true }) _filter: ProductCategoryFilter,
        @CurrentRequest() request: Request
    ): Promise<ProductCategoryResponse> {
        return this.factoryService.forwardRequest(request)
    }

    @Query(_return => ProductTypeResponse, { name: 'productGetTypes' })
    async productGetTypes(
        @Args("filter", { nullable: true }) _filter: ProductTypeFilter,
        @CurrentRequest() request: Request
    ): Promise<ProductTypeResponse> {
        return this.factoryService.forwardRequest(request)
    }

    @Mutation(_return => ProductBrand, { name: 'productAddBrand' })
    async productAddBrand(
        @Args('arguments') _args: ProductBrandArgs,
        @CurrentRequest() request: Request
    ): Promise<ProductBrand> {
        return this.factoryService.forwardRequest(request)
    }

    @Mutation(_return => ProductCategory, { name: 'productAddCategory' })
    async productAddCategory(
        @Args('arguments') _args: ProductCategoryArgs,
        @CurrentRequest() request: Request
    ): Promise<ProductCategory> {
        return this.factoryService.forwardRequest(request)
    }

    @Mutation(_return => ProductType, { name: 'productAddType' })
    async productAddType(
        @Args('arguments') _args: ProductTypeArgs,
        @CurrentRequest() request: Request
    ): Promise<ProductType> {
        return this.factoryService.forwardRequest(request)
    }
}