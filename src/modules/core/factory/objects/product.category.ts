import { Field, Float, ObjectType } from "@nestjs/graphql"
import { User } from "../../iam/objects/user"
import { ProductBrand } from "./product.brand"

@ObjectType()
export class ProductCategory {
    @Field(_type => String, { nullable: true })
    id: string

    @Field(_type => Float, { nullable: true })
    createdAt: Date

    @Field(_type => Float, { nullable: true })
    updatedAt: Date

    @Field(_type => String, { nullable: true })
    ownerId: string

    @Field(_type => User, { nullable: true })
    owner: User

    @Field(_type => String, { nullable: true })
    name: string

    @Field(_type => String, { nullable: true })
    code: string

    @Field(_type => ProductBrand, { nullable: true })
    brand: string

    //Warranty
    @Field(_type => Float, { nullable: true })
    warrantyMonths: number

    @Field(_type => Float, { nullable: true })
    factoryWarrantyMonths: number
}