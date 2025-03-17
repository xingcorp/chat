import { Args, Mutation, Resolver } from '@nestjs/graphql'
import { FileUpload, GraphQLUpload } from 'graphql-upload'
import { BearerAccessToken, CurrentRequest } from '../middleware/decorator/request.decorator'
import { File } from './objects/file'
import { StorageService } from './storage.service'
import { Request } from 'express'
import { UploadFileArgs } from './storage.args'
import { FileResponse, GeneratePresignedUrlsResponse } from './storage.response'

@Resolver()
export class StorageResolver {
  constructor(private readonly storageService: StorageService) { }

  @Mutation(() => File, { name: 'storageUploadFile' })
  async uploadFile(
    @Args({ name: 'file', type: () => GraphQLUpload }) file: FileUpload,
    @BearerAccessToken() token: string
  ) {
    return await this.storageService.uploadFile(file, token)
  }

  @Mutation(_return => File, { name: "storageDeleteFile" })
  async deleteFile(
    @Args("id") fileId: string,
    @BearerAccessToken() token: string
  ): Promise<File> {
    return this.storageService.deleteFile(token, fileId)
  }

  @Mutation(() => GeneratePresignedUrlsResponse, { name: 'storageGeneratePresignedUrls' })
  async getList(
    @Args('arguments', { nullable: false }) args: UploadFileArgs,
    @BearerAccessToken() token: string
  ): Promise<GeneratePresignedUrlsResponse> {
    return this.storageService.storageGeneratePresignedUrls(token, args)
  }

  @Mutation(() => FileResponse, { name: 'storageActiveUsingFiles' })
  async activeUsingFiles(
    @Args('ids', { type: () => [String], nullable: false }) _fileIds: string[],
    @CurrentRequest() request: Request
  ): Promise<FileResponse> {
    return this.storageService.forwardRequest(request)
  }
}
