import { Field, InputType } from "@nestjs/graphql"

@InputType()
export class ThumbnailParams {
    @Field(_type => String)
    fileType: string

    @Field(_type => String, { nullable: true })
    fileName: string

    @Field(_type => String, { nullable: true })
    size: string
}

@InputType()
export class GeneratePresignedUrlParams {
    @Field(_type => String)
    fileName: string

    @Field(_type => String)
    fileType: string

    @Field(_type => [ThumbnailParams], { nullable: true })
    thumbnailsArg: ThumbnailParams[]
}

@InputType()
export class UploadFileArgs {
    // @Field(() => String, { nullable: false })
    // serviceCode: string

    @Field(() => [GeneratePresignedUrlParams], { nullable: true })
    files: GeneratePresignedUrlParams[]
}