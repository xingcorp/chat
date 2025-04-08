import { Field, ObjectType } from "@nestjs/graphql";

@ObjectType()
export class ImportFileResponse {
  @Field(() => String, { nullable: true })
  fileUrl: string
}
