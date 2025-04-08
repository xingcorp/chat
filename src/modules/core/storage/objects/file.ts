import { Int, Field, Float, ObjectType } from '@nestjs/graphql'

export enum FileCleanType {
  Daily = 'Daily',
  Weekly = 'Weekly',
  Monthly = 'Monthly',
  Yearly = 'Yearly',
  Never = 'Never'
}

@ObjectType()
export class FileThumbnail {
  @Field(_type => String, { nullable: true })
  url: string

  @Field(_type => String, { nullable: true })
  key: string

  @Field(_type => String, { nullable: true })
  type: string

  @Field(_type => String, { nullable: true })
  size: string
  
  @Field(_type => String, { nullable: true })
  name: string
}

@ObjectType()
export class File {
  @Field(() => String)
  id: string

  @Field({ nullable: true, defaultValue: null })
  name: string

  @Field({ nullable: true, defaultValue: null })
  mimetype: string

  @Field({ nullable: true, defaultValue: null })
  encoding: string

  @Field(() => Int, { nullable: true, defaultValue: null })
  size: number

  @Field({ nullable: true, defaultValue: null })
  location: string

  @Field(_type => [FileThumbnail], { nullable: true })
  thumbnails: FileThumbnail[]

  @Field(() => Float, { defaultValue: 0 })
  createdAt: Date

  @Field(() => Float, { defaultValue: 0 })
  updatedAt: Date

  public backup() {
    return JSON.stringify({
      id: this.id,
      name: this.name,
      mimetype: this.mimetype,
      encoding: this.encoding,
      size: this.size,
      location: this.location,
      createdAt: this.createdAt,
      updatedAt: this.updatedAt
    })
  }

  static restore(snapshot: string) {
    try {
      const dict = JSON.parse(snapshot)
      const result = new File()

      result.id = dict.id
      ;(result.name = dict.name),
        (result.mimetype = dict.mimetype),
        (result.encoding = dict.encoding),
        (result.size = dict.size),
        (result.location = dict.location),
        (result.createdAt = dict.createdAt),
        (result.updatedAt = dict.updatedAt)

      return result
    } catch (error) {
      console.log(`File restore has error: ${error}`)
    }

    return null
  }
}
