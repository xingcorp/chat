import { Injectable } from '@nestjs/common'
import * as AWS from 'aws-sdk'
import { FileUpload } from 'graphql-upload'
import * as path from 'path'
import { buildExceptionResponse } from '../common/error.builder'
import { GraphQLClient } from '../common/graphql.client'
import { File, FileCleanType } from './objects/file'
import * as GQLTag from 'graphql-tag'
import { generateNoneDashUUID, generateUUID } from '../common/uuid'
import { RequestContext } from "@common/context/request.context";
import { OfficeError } from "@common/office.error";
import { UploadFileArgs } from './storage.args'

const FILE_DETAIL = GQLTag.gql`
  query fileDetail($fileId: String!) {
    storageGetFileDetail(id: $fileId) {
      id
      name
      mimetype
      encoding
      size
      location
      createdAt
      updatedAt
    }
  }
`

const FILES_DETAIL = GQLTag.gql`
  query filesDetail($fileIds: [String!]!) {
    storageGetFilesDetail(ids: $fileIds) {
      total
      count
      files {
        id
        name
        mimetype
        encoding
        size
        location
        createdAt
        updatedAt
      }
    }
  }
`

const REGISTER_UPLOAD_FILE = GQLTag.gql`
  mutation registerUploadFile($fileInfo: FileArgs!) {
    storageRegisterUploadFile(arguments: $fileInfo) {
      id
      name
      mimetype
      encoding
      size
      location
      createdAt
      updatedAt
    }
  }
`

const REGISTER_USING_FILES = GQLTag.gql`
  mutation registerUsingFile($ids: [String!]!, $cleanType: String!) {
    storageRegisterUsingFile(ids: $ids, cleanType: $cleanType) {
      total
      count
      files {
        id
        name
        mimetype
        encoding
        size
        location
        createdAt
        updatedAt
      }
    }
  }
`

const DELETE_FILE = GQLTag.gql`
  mutation deleteFile($fileId: String!) {
    storageDeleteFile(id: $fileId) {
      id
      name
      mimetype
      encoding
      size
      location
      createdAt
      updatedAt
    }
  }
`

const GENERATE_PRESIGNURLS = GQLTag.gql`
  mutation storageGeneratePresignedUrls($arguments: UploadFileArgs!) {
    storageGeneratePresignedUrls(arguments: $arguments) {
        total
        data {
            id
            presignedUrl
            path
            url
            expiredIn
            thumbnailPresignedUrls {
                url
                key
                type
                size
                name
                presignedUrl
            }
        }
    }
  }
`

const ACTIVE_FILES = GQLTag.gql`
  mutation StorageActiveUsingFiles($ids: [String!]!) {
    storageActiveUsingFiles(ids: $ids) {
        count
        total
        files {
            id
        }
    }
  }
`

@Injectable()
export class StorageService extends GraphQLClient {
  private readonly serviceCode = process.env.SERVICE_CODE || 'office'

  constructor() {
    super(process.env.SRT_STORAGE_MICROSERVICE_DOMAIN)
  }

  private awsS3 = new AWS.S3({
    credentials: {
      accessKeyId: process.env.AWS_IAM_ACCESS_KEY_ID as string,
      secretAccessKey: process.env.AWS_IAM_ACCESS_KEY_SECRET as string
    },
    region: process.env.AWS_S3_REGION,
    params: {
      ACL: 'public-read',
      Bucket: process.env.AWS_S3_BUCKET
    }
  })

  private uploadToS3 = async (
    file: FileUpload,
    folder: string
  ): Promise<AWS.S3.ManagedUpload.SendData> => {
    const { createReadStream, filename, mimetype, encoding } = file
    const timestamp = new Date().getTime()
    const uniqueFileName = `${generateNoneDashUUID()}_${filename}`

    let filePath = path.join(folder, `${timestamp}_${uniqueFileName}`)
    if (process.platform === 'win32') {
      filePath = `${folder}/${timestamp}_${uniqueFileName}`
    }

    const bucket = process.env.AWS_S3_BUCKET as string
    console.log(`Upload to S3: ${filePath}-${mimetype}-${encoding}-${bucket}`)

    return new Promise((resolve, reject) => {
      this.awsS3.upload(
        {
          Body: createReadStream(),
          Key: filePath,
          ContentType: mimetype,
          ContentEncoding: encoding,
          Bucket: bucket
        },
        (error, data) => {
          if (error) {
            console.log('Error when upload file to S3...', error)
            reject(error)
          } else {
            console.log('Successfully uploaded file to S3...', data)
            resolve(data as AWS.S3.ManagedUpload.SendData)
          }
        }
      )
    })
  }

  private objectToS3(
    buffer: any,
    folder: string,
    filename: string,
    contentType: string
  ): Promise<AWS.S3.ManagedUpload.SendData> {
    const uniqueFileName = `${generateNoneDashUUID()}_${filename}`
    let filePath = path.join(folder, `${uniqueFileName}`)
    if (process.platform === 'win32') {
      filePath = `${folder}/${uniqueFileName}`
    }

    const bucket = process.env.AWS_S3_BUCKET as string
    console.log(`Upload object to S3: ${filePath}-${bucket}`)

    return new Promise((resolve, reject) => {
      this.awsS3.putObject({
        Body: buffer,
        Key: filePath,
        ContentType: contentType,
        ContentEncoding: 'bytes',
        Bucket: bucket
      }, (error, data) => {
        if (error) {
          console.log('Error when upload file to S3...', error)
          reject(error)
        } else {
          console.log('Successfully uploaded file to S3...', data)
          const result = data as AWS.S3.ManagedUpload.SendData
          resolve({
            ...result,
            Key: filePath,
            Bucket: bucket,
            Location: `${process.env.AWS_S3_OBJECT_URL}/${filePath}`
          })
        }
      }
      )
    })
  }

  private getS3FileSize = (key: string) => {
    return this.awsS3
      .headObject({
        Key: key,
        Bucket: process.env.AWS_S3_BUCKET as string
      })
      .promise()
      .then((res) => res.ContentLength)
  }

  public getFileDetail = async (token: string, fileId: string) => {
    return this.sendQuery(token, FILE_DETAIL, { fileId: fileId })
  }

  public getFilesDetail = async (token: string, fileIds: string[]) => {
    return this.sendQuery(token, FILES_DETAIL, { fileIds: fileIds })
  }

  public uploadObject = async (
    token: string,
    buffer: any,
    filename: string,
    contentType: string,
    folder = "",
    cleanType: FileCleanType = FileCleanType.Daily,
  ): Promise<File> => {
    const code = this.serviceCode ? this.serviceCode : this.serviceCode
    let parent: string = code
    if (folder !== null) {
      parent = path.join(code, folder)
      if (process.platform === 'win32') {
        parent = `${code}/${folder}`
      }
    }

    const s3Response = await this.objectToS3(buffer, parent, filename, contentType)
    const fileSize = await this.getS3FileSize(s3Response.Key)

    return await this.sendMutationThrowError(
      token,
      REGISTER_UPLOAD_FILE,
      {
        fileInfo: {
          serviceCode: this.serviceCode,
          name: filename,
          mimetype: contentType,
          etag: s3Response.ETag,
          key: s3Response.Key,
          bucket: s3Response.Bucket,
          location: s3Response.Location,
          encoding: 'bytes',
          size: fileSize,
          cleanType: cleanType
        }
      }
    )
  }

  public getObject = async (
    filePath
  ): Promise<AWS.S3.Types.GetObjectOutput> => {
    return new Promise((resolve, reject) => {
      const params = {
        Bucket: process.env.AWS_S3_DOCUMENT_BUCKET as string,
        Key: filePath
      };

      this.awsS3.getObject(params, (err, data) => {
        if (err) {
          reject(err);
        } else {
          resolve(data as AWS.S3.Types.GetObjectOutput)
        }
      })
    });
  }

  public uploadFile = async (
    file: FileUpload,
    token: string,
    cleanType: FileCleanType = FileCleanType.Daily,
    folder: string = null,
    serviceCode = null
  ): Promise<File> => {
    try {
      const code = serviceCode ? serviceCode : this.serviceCode
      let parent: string = code
      if (folder !== null) {
        parent = path.join(code, folder)
        if (process.platform === 'win32') {
          parent = `${code}/${folder}`
        }
      }

      const s3Response = await this.uploadToS3(file, parent)
      const fileSize = await this.getS3FileSize(s3Response.Key)
      const { filename, mimetype, encoding } = await file

      return await this.sendMutationThrowError(
        token,
        REGISTER_UPLOAD_FILE,
        {
          fileInfo: {
            serviceCode: this.serviceCode,
            name: filename,
            mimetype: mimetype,
            encoding: encoding,
            etag: s3Response.ETag,
            key: s3Response.Key,
            bucket: s3Response.Bucket,
            location: s3Response.Location,
            size: fileSize,
            cleanType: cleanType
          }
        }
      )
    } catch (error) {
      console.log('Upload file has failed: ', error)
      throw buildExceptionResponse(error)
    }
  }

  public registerUsingFiles(
    token: string,
    fileIds: string[],
    cleanType: FileCleanType
  ): Promise<File> {
    return this.sendMutationThrowError(token, REGISTER_USING_FILES, {
      ids: fileIds,
      cleanType: cleanType
    })
  }

  public deleteFile(token: string, fileId: string) {
    return this.sendMutationThrowError(token, DELETE_FILE, {
      fileId: fileId
    })
  }

  async generatePresignedUrlToUpload(key: string, fileType: string, expiredIn = 600): Promise<string> {
    const params = {
      Bucket: process.env.AWS_S3_BUCKET as string,
      Key: key,
      ContentType: fileType,
      Expires: expiredIn,
    };
    return this.awsS3.getSignedUrlPromise('putObject', params)
  }

  async validateAttachments(attachmentIds: string[]) {
    if (!attachmentIds) return
    for (const attachmentId of attachmentIds) {
      const { data, error } = await this.getFileDetail(RequestContext.currentToken(), attachmentId)
      if (error) throw error
      if (!data) throw OfficeError.FileNotExisted
    }
  }

  public async storageGeneratePresignedUrls(bearerToken: string, args: UploadFileArgs) {
    return await this.sendMutationThrowError(
      bearerToken,
      GENERATE_PRESIGNURLS,
      {
        arguments: {
          serviceCode: process.env.SERVICE_CODE as string,
          files: args.files
        }
      }
    )
  }

  async activeUsingFiles(bearerToken: string, ids: string[]) {
    return await this.sendMutationThrowError(
      bearerToken,
      ACTIVE_FILES,
      {
        ids
      }
    )
  }
}
