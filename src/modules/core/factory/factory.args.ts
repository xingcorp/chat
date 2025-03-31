import { InputType, Field, Int } from "@nestjs/graphql"

@InputType()
export class ProductBrandArgs {
    @Field(_type => String, { nullable: false })
    name: string

    @Field(_type => String, { nullable: false })
    code: string
}

@InputType()
export class ProductCategoryArgs {
    @Field(_type => String, { nullable: false })
    name: string

    @Field(_type => String,  { nullable: false })
    code: string

    @Field(_type => String, { nullable: false })
    brandId: string

    @Field(_type => Int, { nullable: false })
    warrantyMonths: number

    @Field(_type => Int, { nullable: false })
    factoryWarrantyMonths: number
}

@InputType()
export class ProductTypeArgs {
    @Field(_type => String, { nullable: false })
    name: string
    
    @Field(_type => String,  { nullable: false })
    code: string

    @Field(_type => String, { nullable: false })
    productCategoryId: string

    @Field(_type => Int, { nullable: false, defaultValue: 0 })
    warrantyMonths: number

    @Field(_type => Int, { nullable: false, defaultValue: 0 })
    factoryWarrantyMonths: number
}

@InputType()
export class ProductBrandFilter {
    @Field({ nullable: true, defaultValue: 0})
    page?: number

    @Field({ nullable: true, defaultValue: 100})
    size?: number
    
    @Field({ nullable: true })
    keyword?: string
}

@InputType()
export class ProductCategoryFilter {
    @Field({ nullable: true, defaultValue: 0})
    page?: number

    @Field({ nullable: true, defaultValue: 100})
    size?: number

    @Field({ nullable: true })
    productBrandId? :string
    
    @Field({ nullable: true })
    keyword?: string
}

@InputType()
export class ProductTypeFilter {
    @Field({ nullable: true, defaultValue: 0})
    page?: number

    @Field({ nullable: true, defaultValue: 100})
    size?: number

    @Field({ nullable: true })
    productCategoryId? :string
    
    @Field({ nullable: true })
    keyword?: string
}