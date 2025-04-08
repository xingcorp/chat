import { Field, InputType } from "@nestjs/graphql";
import { IsExistAttachmentsIamValidate } from "@decorators/validation/iam/is-exist-attachments.iam.validate";
import { ValidateIf } from "class-validator";

@InputType()
export class TaskCommentCreate {
    @Field(_type => String, { nullable: false })
    taskId: string

    @Field(_type => String, { nullable: false })
    comment: string

    @Field(() => [String], { nullable: true })
    @ValidateIf(o => o.attachmentIds)
    @IsExistAttachmentsIamValidate()
    attachmentIds: string[]

    @Field(() => [String], { nullable: true })
    @ValidateIf(o => o.imageIds)
    @IsExistAttachmentsIamValidate()
    imageIds: string[]
}

@InputType()
export class TaskCommentUpdate {
    @Field(_type => String, { nullable: false })
    id: string

    @Field(_type => String, { nullable: false })
    comment: string
}
