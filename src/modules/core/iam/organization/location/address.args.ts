import { Field, InputType } from "@nestjs/graphql"

@InputType()
export class LocationArgs {
  @Field({ nullable: false })
  latitude: number

  @Field({ nullable: false })
  longitude: number
}

@InputType()
export class AddressTextArgs {
  @Field({ nullable: false })
  text: string
}

@InputType()
export class ZoneNameArgs {
    @Field({ nullable: false })
    province: string

    @Field({ nullable: false })
    district: string

    @Field({ nullable: false })
    ward: string
}