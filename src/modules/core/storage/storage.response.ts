import { PagingData } from "@models/base/paging.response"
import { Field, Float, Int, ObjectType } from "@nestjs/graphql"
import { File, FileThumbnail } from "./objects/file"

@ObjectType({ implements: PagingData })
export class FileResponse implements PagingData {
    total: number
    count: number

    @Field(_type => [File], { nullable: true })
    files?: File[]
}

@ObjectType()
export class GeneratePresignedUrlsResponse {
    @Field(_type => Int)
    total: number

    @Field(_type => [GeneratePresignedUrlResponse])
    data: GeneratePresignedUrlResponse[]
}

@ObjectType()
export class GeneratePresignedUrlResponse {
    @Field(_type => String)
    id: String

    @Field(_type => String)
    presignedUrl: String

    @Field(_type => String)
    path: String

    @Field(_type => String)
    url?: String

    @Field(_type => Float)
    expiredIn: number

    @Field(_type => [ThumbnailPresignedUrlRes])
    thumbnailPresignedUrls: ThumbnailPresignedUrlRes[]
}

@ObjectType()
export class ThumbnailPresignedUrlRes extends FileThumbnail {
    @Field(_type => String)
    presignedUrl: string
}