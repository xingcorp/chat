import { Field, Float, ObjectType } from "@nestjs/graphql"
import { User } from "../../iam/objects/user"
import { ProductCategory } from "./product.category"
import { ProductType } from "./product.type"

@ObjectType()
export class Product {
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

    @Field(_type => ProductCategory, { nullable: true })
    productCategory: string

    @Field(_type => ProductType, { nullable: true })
    productType: string

    @Field(_type => String, { nullable: true })
    name: string

    @Field(_type => String, { nullable: true })
    code: string

    @Field(_type => String, { nullable: true })
    serial: string

    @Field(_type => String, { nullable: true })
    description: string

    @Field(_type => String, { nullable: true })
    origin: string

    @Field(_type => Float, { nullable: true })
    price: number

    @Field(_type => Float, { nullable: true })
    point: number

    @Field(_type => String, { nullable: true })
    warrantyCode: string

    @Field(_type => Float, { nullable: true })
    warrantyMonths: number
}