import { Field, ObjectType } from '@nestjs/graphql'

@ObjectType()
export class Carrier {
  @Field(() => String, { nullable: true })
  id: string

  @Field(() => String, { nullable: true })
  name: string

  public backup() {
    return JSON.stringify({
      id: this.id,
      name: this.name
    })
  }

  static restore(snapshot: string) {
    try {
      const dict = JSON.parse(snapshot)
      const result = new Carrier()

      result.id = dict.id
      result.name = dict.name

      return result
    } catch (error) {
      console.log(`Carrier restore has error: ${error}`)
    }

    return null
  }
}
