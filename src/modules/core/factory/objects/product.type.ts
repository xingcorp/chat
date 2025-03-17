import { Field, Float, ObjectType } from "@nestjs/graphql"
import { User } from "../../iam/objects/user"
import { ProductCategory } from "./product.category"

@ObjectType()
export class ProductType {
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

    @Field(_type => String, { nullable: false })
    name: string

    @Field(_type => String, { nullable: false })
    code: string

    @Field(_type => ProductCategory, { nullable: false })
    productCategory: string

    @Field(_type => Float, { nullable: true })
    price: number

    @Field(_type => String, { nullable: false })
    model: string

    //Warranty
    @Field(_type => Float, { nullable: true })
    warrantyMonths: number

    @Field(_type => Float, { nullable: true })
    factoryWarrantyMonths: number
}