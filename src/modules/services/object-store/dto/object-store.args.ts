import { Field, InputType } from "@nestjs/graphql";

@InputType()
export class ViewObjectArgs {
    @Field({ nullable: false })
    token: string
}