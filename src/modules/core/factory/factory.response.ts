import { ObjectType, Field, Int } from "@nestjs/graphql"
import { ProductBrand } from "./objects/product.brand"
import { ProductCategory } from "./objects/product.category"
import { ProductType } from "./objects/product.type"

@ObjectType()
export class ProductBrandResponse {
    @Field(_type => Int, { defaultValue: 0})
    total: number

    @Field(_type => Int, { defaultValue: 0})
    count: number
    
    @Field(_type => [ProductBrand], { nullable: true })
    productBrands?: ProductBrand[]
}

@ObjectType()
export class ProductCategoryResponse {
    @Field(_type => Int, { defaultValue: 0})
    total: number

    @Field(_type => Int, { defaultValue: 0})
    count: number
    
    @Field(_type => [ProductCategory], { nullable: true })
    productCategories?: ProductCategory[]
}

@ObjectType()
export class ProductTypeResponse {
    @Field(_type => Int, { defaultValue: 0})
    total: number

    @Field(_type => Int, { defaultValue: 0})
    count: number
    
    @Field(_type => [ProductType], { nullable: true })
    productTypes?: ProductType[]
}