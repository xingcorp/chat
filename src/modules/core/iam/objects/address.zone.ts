import { Field, Float, ObjectType } from '@nestjs/graphql'

export enum AddressLevel {
  Country = 'Country',
  Province = 'Province',
  District = 'District',
  Ward = 'Ward'
}

@ObjectType()
export class AddressZone {
  @Field(() => String, { nullable: true })
  id: string

  @Field(() => Float, { nullable: true })
  createdAt: Date

  @Field(() => Float, { nullable: true })
  updatedAt: Date

  @Field(() => String, { nullable: true })
  code: string

  @Field(() => String, { nullable: true })
  name: string

  @Field(() => String, { nullable: true })
  fullname: string

  @Field(() => String, { nullable: true })
  english: string

  @Field(() => String, { nullable: true })
  level: AddressLevel

  @Field(() => AddressZone, { nullable: true, defaultValue: null })
  parent: AddressZone

  public backup() {
    return JSON.stringify({
      id: this.id,
      createdAt: this.createdAt,
      updatedAt: this.updatedAt,
      code: this.code,
      name: this.name,
      fullname: this.fullname,
      english: this.english,
      level: this.level,
      parent: this.parent ? this.parent.backup() : null
    })
  }

  static restore(snapshot: string) {
    try {
      const dict = JSON.parse(snapshot)
      const result = new AddressZone()

      result.id = dict.id
      result.createdAt = dict.createdAt
      result.updatedAt = dict.updatedAt
      result.code = dict.code
      result.name = dict.name
      result.fullname = dict.fullname
      result.english = dict.english
      result.level = dict.level
      result.parent = dict.parent ? AddressZone.restore(dict.parent) : null

      return result
    } catch (error) {
      console.log(`Address zone restore has error: ${error}`)
    }
    return null
  }
}
