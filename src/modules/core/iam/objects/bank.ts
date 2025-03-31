import { Field, ObjectType } from '@nestjs/graphql'

@ObjectType()
export class Bank {
  @Field(() => String, { nullable: true })
  id: string

  @Field(() => String, { nullable: true })
  vn_name: string

  @Field(() => String, { nullable: true })
  en_name: string

  // @Field(() => String, { nullable: true })
  // country: string

  // @Field(() => String, { nullable: true })
  // code: string

  @Field(() => String, { nullable: true })
  type: string

  @Field(() => String, { nullable: true })
  brandName: string

  @Field(() => String, { nullable: true })
  swiffCode: string

  @Field(() => String, { nullable: true })
  website: string

  @Field(() => String, { nullable: true })
  headquarter: string

  // public backup() {
  //   return JSON.stringify({
  //     id: this.id,
  //     vn_name: this.vn_name,
  //     en_name: this.en_name,
  //     country: this.country,
  //     code: this.code
  //   })
  // }

  // static restore(snapshot: string) {
  //   try {
  //     const dict = JSON.parse(snapshot)
  //     const result = new Bank()

  //     result.id = dict.id
  //     result.vn_name = dict.vn_name
  //     result.en_name = dict.en_name
  //     result.country = dict.country
  //     result.code = dict.code

  //     return result
  //   } catch (error) {
  //     console.log(`Bank restore has error: ${error}`)
  //   }

  //   return null
  // }
}
