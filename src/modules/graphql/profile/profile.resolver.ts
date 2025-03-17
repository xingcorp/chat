import { Inject, SetMetadata, forwardRef } from "@nestjs/common";
import { Args, Mutation, Query, Resolver } from "@nestjs/graphql";
import { OfficeError } from "src/common/office.error";
import { InfoBlock, OfficeTitle, UserDepartment } from "src/models/entities";
import { ObjectStatus } from "src/models/entities/profile.info.block";
import { DataType, InfoField } from "src/models/entities/profile.info.field";
import { ServiceActions, ServiceKeys, UserType } from "src/modules/core/middleware/guard/service.action";
import { ILike, MoreThanOrEqual } from "typeorm";
import { EditInfoBlockArgs, EditInfoFieldArgs, EditOfficeTitleArgs, InfoBlockArgs, InfoFieldArgs, OfficeTitleArgs, OfficeTitleFilter, UpsertBlockArgs, UpsertFieldArgs, UpsertTitleArgs } from "./profile.args";
import { BulkUpsertBlockResponse, BulkUpsertFieldResponse, BulkUpsertTitleResponse, InfoBlockResponse, InfoFieldResponse, OfficeTitleResponse, UpsertBlockResponse, UpsertFieldResponse, UpsertTitleResponse } from "./profile.response";
import { RequesterId } from "src/modules/core/middleware/decorator/user.decorator";
import { ProfileService } from "./profile.service";
import { OfficeBlockType } from "@enum/block/block.enum";

@Resolver()
export class ProfileResolver {
  constructor(
    @Inject(forwardRef(() => ProfileService))
    private readonly profileService: ProfileService
  ) { }

  @Mutation(() => InfoBlock, { name: 'profileAddBlock' })
  @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
  @SetMetadata(ServiceKeys.UserType, [UserType.SYSTEM_USER])
  async profileAddBlock(
    @Args('arguments', { nullable: false }) args: InfoBlockArgs,
    @RequesterId() requesterId: string,
  ): Promise<InfoBlock> {
    const existedBlock = await InfoBlock.findOne({
      where: {
        name: args.name,
        relationType: OfficeBlockType.User
      }
    })

    if (existedBlock) {
      throw OfficeError.ProfileBlockIsExisted
    }

    const block = InfoBlock.create({
      name: args.name,
      note: args.note,
      status: args.status,
      createdBy: requesterId,
      updatedBy: requesterId
    })

    return block.save()
  }

  @Mutation(() => InfoBlock, { name: 'profileEditBlock' })
  @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
  @SetMetadata(ServiceKeys.UserType, [UserType.SYSTEM_USER])
  async profileEditBlock(
    @Args('arguments', { nullable: false }) args: EditInfoBlockArgs,
    @RequesterId() requesterId: string,
  ): Promise<InfoBlock> {
    const existedBlock = await InfoBlock.findOne({
      where: {
        id: args.id,
        relationType: OfficeBlockType.User
      }
    })

    if (!existedBlock) {
      throw OfficeError.ProfileBlockNotExisted
    }

    if (args.name && args.name !== existedBlock.name) {
      const existedName = await InfoBlock.findOne({
        where: {
          name: args.name,
          relationType: OfficeBlockType.User
        }
      })
      if (existedName) {
        throw OfficeError.ProfileBlockIsExisted
      }
      existedBlock.name = args.name
    }
    if (args.note !== undefined) existedBlock.note = args.note
    if (args.status) existedBlock.status = args.status
    if (args.order && args.order !== existedBlock.order) {
      const updateBlocks: InfoBlock[] = []
      const [blocks, total] = await InfoBlock.findAndCount({
        where: {
          relationType: OfficeBlockType.User
        }
      })
      const last = total || 1
      const order = args.order > last ? last : (args.order < 1 ? 1 : args.order)
      if (order > existedBlock.order) {
        for (const iterator of blocks) {
          if (iterator.order >= existedBlock.order && iterator.order <= order && iterator.id !== existedBlock.id) {
            iterator.order = iterator.order - 1
            updateBlocks.push(iterator)
          }
        }
      } else {
        for (const iterator of blocks) {
          if (iterator.order >= order && iterator.order <= existedBlock.order && iterator.id !== existedBlock.id) {
            iterator.order = iterator.order + 1
            updateBlocks.push(iterator)
          }
        }
      }

      existedBlock.order = order
      await InfoBlock.save(updateBlocks)
    }

    existedBlock.updatedBy = requesterId
    return existedBlock.save()
  }

  @Query(_return => InfoBlockResponse, { name: "profileGetBlocks" })
  @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
  async profileGetBlocks(): Promise<InfoBlockResponse> {
    const [list, count] = await InfoBlock.findAndCount({
      where: {
        relationType: OfficeBlockType.User
      },
      order: {
        order: "ASC"
      }
    })

    return {
      total: count,
      count: list.length,
      blocks: list
    }
  }

  @Mutation(_type => BulkUpsertBlockResponse, { nullable: true, name: "profileBlockBulkUpsert" })
  @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
  @SetMetadata(ServiceKeys.UserType, [UserType.SYSTEM_USER])
  async profileBlockBulkUpsert(
    @Args('blocks', { type: () => [UpsertBlockArgs] }) blocks: UpsertBlockArgs[],
    @RequesterId() requesterId: string,
  ): Promise<BulkUpsertBlockResponse> {
    try {
      const response: UpsertBlockResponse[] = []
      const existedNames: String[] = []
      const upsertBlocks: InfoBlock[] = []
      for (const input of blocks) {
        if (!input.name || !input.status) {
          response.push({ ...input, errorMessage: 'Vui lòng không để trống trường bắt buộc' })
          continue
        }

        if (!Object.keys(ObjectStatus).includes(input.status)) {
          response.push({ ...input, errorMessage: 'Vui lòng nhập giá trị là Active hoặc Inactive' })
          continue
        }

        const existedBlockName = await InfoBlock.findOne({
          where: {
            name: input.name,
            relationType: OfficeBlockType.User
          }
        })

        if (input.code) {
          // update
          const existedBlock = await InfoBlock.findOne({
            where: { code: input.code, relationType: OfficeBlockType.User }
          })

          if (!existedBlock) {
            response.push({ ...input, errorMessage: 'Mã khối không tồn tại' })
            continue
          }

          if ((existedBlockName && existedBlockName.code !== existedBlock.code) || existedNames.includes(input.name)) {
            response.push({ ...input, errorMessage: 'Tên khối đã tồn tại' })
            continue
          }

          existedBlock.name = input.name
          existedBlock.status = ObjectStatus[input.status]
          existedBlock.updatedBy = requesterId
          upsertBlocks.push(existedBlock)
          response.push({ ...input, errorMessage: 'Cập nhật thành công' })
        } else {
          // insert
          if (existedBlockName || existedNames.includes(input.name)) {
            response.push({ ...input, errorMessage: 'Tên khối đã tồn tại' })
            continue
          }

          upsertBlocks.push(InfoBlock.create({
            name: input.name,
            status: ObjectStatus[input.status],
            createdBy: requesterId,
            updatedBy: requesterId
          }))
          response.push({ ...input, errorMessage: 'Tạo mới thành công' })
          existedNames.push(input.name)
        }
      }

      // await InfoBlock.save(upsertBlocks)
      for (const iterator of upsertBlocks) {
        await iterator.save()
      }

      return {
        total: response.length,
        count: response.length,
        records: response
      }
    } catch (error) {
      console.log(`Bulk upsert info block has error: ${error}`)
      throw error
    }
  }

  @Mutation(() => InfoField, { name: 'profileAddField' })
  @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
  @SetMetadata(ServiceKeys.UserType, [UserType.SYSTEM_USER])
  async profileAddField(
    @Args('arguments', { nullable: false }) args: InfoFieldArgs,
    @RequesterId() requesterId: string,
  ): Promise<InfoField> {
    const existedField = await InfoField.findOne({
      where: {
        name: args.name
      }
    })
    if (existedField) {
      throw OfficeError.ProfileFieldIsExisted
    }

    const existedBlock = await InfoBlock.findOne({
      where: {
        id: args.blockId,
        relationType: OfficeBlockType.User
      }
    })
    if (!existedBlock) {
      throw OfficeError.ProfileBlockNotExisted
    }

    const field = InfoField.create({
      name: args.name,
      blockId: args.blockId,
      note: args.note,
      dataType: args.dataType,
      required: args.required,
      status: args.status,
      createdBy: requesterId,
      updatedBy: requesterId
    })

    if (field.dataType === DataType.List) {
      field.optionItems = args.optionItems || []
    }

    return field.save()
  }

  @Mutation(() => InfoField, { name: 'profileEditField' })
  @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
  @SetMetadata(ServiceKeys.UserType, [UserType.SYSTEM_USER])
  async profileEditField(
    @Args('arguments', { nullable: false }) args: EditInfoFieldArgs,
    @RequesterId() requesterId: string,
  ): Promise<InfoField> {
    const existedField = await InfoField.findOne({
      where: {
        id: args.id
      }
    })

    if (!existedField) {
      throw OfficeError.ProfileFieldNotExisted
    }

    if (args.name && args.name !== existedField.name) {
      const existedName = await InfoField.findOne({
        where: {
          name: args.name
        }
      })
      if (existedName) {
        throw OfficeError.ProfileFieldIsExisted
      }
      existedField.name = args.name
    }
    if (args.dataType) existedField.dataType = args.dataType
    // if (args.fieldLength !== undefined) existedField.fieldLength = args.fieldLength
    if (args.note !== undefined) existedField.note = args.note
    if (args.required !== undefined) existedField.required = args.required
    if (args.status) existedField.status = args.status
    if (args.optionItems && existedField.dataType === DataType.List) {
      existedField.optionItems = args.optionItems || []
    } else {
      existedField.optionItems = null
    }
    // if (args.displayInBrief !== undefined) existedField.displayInBrief = args.displayInBrief
    if (args.order && args.order !== existedField.order) {
      const updateFields: InfoField[] = []
      const [fields, total] = await InfoField.findAndCount({
        where: {
          blockId: existedField.blockId
        }
      })
      const last = total || 1
      const order = args.order > last ? last : (args.order < 1 ? 1 : args.order)
      if (order > existedField.order) {
        for (const iterator of fields) {
          if (iterator.order >= existedField.order && iterator.order <= order && iterator.id !== existedField.id) {
            iterator.order = iterator.order - 1
            updateFields.push(iterator)
          }
        }
      } else {
        for (const iterator of fields) {
          if (iterator.order >= order && iterator.order <= existedField.order && iterator.id !== existedField.id) {
            iterator.order = iterator.order + 1
            updateFields.push(iterator)
          }
        }
      }

      existedField.order = order
      await InfoField.save(updateFields)
    }

    existedField.updatedBy = requesterId
    return existedField.save()
  }

  @Query(_return => InfoFieldResponse, { name: "profileGetFields" })
  @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
  async profileGetFields(
    @Args("blockId", { nullable: true }) blockId: string
  ): Promise<InfoFieldResponse> {
    const [list, count] = blockId ? await InfoField.findAndCount({
      where: {
        blockId: blockId
      },
      order: {
        order: "ASC"
      }
    }) : await InfoField.findAndCount({
      where: {},
      order: {
        no: "ASC"
      }
    })

    return {
      total: count,
      count: list.length,
      fields: list
    }
  }

  @Mutation(_type => BulkUpsertFieldResponse, { nullable: true, name: "profileFieldBulkUpsert" })
  @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
  @SetMetadata(ServiceKeys.UserType, [UserType.SYSTEM_USER])
  async profileFieldBulkUpsert(
    @Args('fields', { type: () => [UpsertFieldArgs] }) fields: UpsertFieldArgs[],
    @RequesterId() requesterId: string,
  ): Promise<BulkUpsertFieldResponse> {
    try {
      const response: UpsertFieldResponse[] = []
      const existedNames: String[] = []
      const upsertFields: InfoField[] = []
      for (const input of fields) {
        if (!input.name || !input.blockCode || !input.dataType || !input.status) {
          response.push({ ...input, errorMessage: 'Vui lòng không để trống trường bắt buộc' })
          continue
        }

        if (!Object.keys(ObjectStatus).includes(input.status)) {
          response.push({ ...input, errorMessage: 'Vui lòng nhập giá trị là Active hoặc Inactive' })
          continue
        }

        if (!Object.keys(DataType).includes(input.dataType)) {
          response.push({ ...input, errorMessage: "Vui lòng nhập định dạng là 'Date/List/Text'" })
          continue
        }

        const block = await InfoBlock.findOne({
          where: { code: input.blockCode }
        })

        if (!block) {
          response.push({ ...input, errorMessage: 'Mã khối không tồn tại' })
          continue
        }

        // if (input.required && !["Y", "N"].includes(input.required)) {
        //   response.push({ ...input, errorMessage: "Vui lòng nhập định dạng là 'Date/List/Text'" })
        //   continue
        // }

        const existedFieldName = await InfoField.findOne({
          where: {
            name: input.name,
            blockId: block.id
          }
        })

        if (input.code) {
          // update
          const existedField = await InfoField.findOne({
            where: { code: input.code }
          })

          if (!existedField) {
            response.push({ ...input, errorMessage: 'Mã trường không tồn tại' })
            continue
          }

          if ((existedFieldName && existedFieldName.code !== existedField.code) || existedNames.includes(input.name)) {
            response.push({ ...input, errorMessage: 'Tên trường đã tồn tại' })
            continue
          }

          existedField.name = input.name
          existedField.status = ObjectStatus[input.status]
          if (input.required === "Y") {
            existedField.required = true
          } else if (input.required === "N") {
            existedField.required = false
          }
          existedField.dataType = DataType[input.dataType]
          existedField.blockId = block.id
          existedField.note = input.note
          if (existedField.dataType === DataType.List) {
            existedField.optionItems = input.optionItems ? input.optionItems.split(",") : []
          } else {
            existedField.optionItems = null
          }
          existedField.updatedBy = requesterId
          upsertFields.push(existedField)
          response.push({ ...input, errorMessage: 'Cập nhật thành công' })
        } else {
          // insert
          if (existedFieldName || existedNames.includes(input.name)) {
            response.push({ ...input, errorMessage: 'Tên trường đã tồn tại' })
            continue
          }

          const newField = InfoField.create({
            name: input.name,
            blockId: block.id,
            note: input.note,
            dataType: DataType[input.dataType],
            required: input.required === "Y" ? true : false,
            status: ObjectStatus[input.status],
            createdBy: requesterId,
            updatedBy: requesterId
          })
          if (newField.dataType === DataType.List) {
            newField.optionItems = input.optionItems ? input.optionItems.split(",") : []
          }
          upsertFields.push(newField)
          response.push({ ...input, errorMessage: 'Tạo mới thành công' })
          existedNames.push(input.name)
        }
      }

      for (const iterator of upsertFields) {
        await iterator.save()
      }

      return {
        total: response.length,
        count: response.length,
        records: response
      }
    } catch (error) {
      console.log(`Bulk upsert info field has error: ${error}`)
      throw error
    }
  }

  @Mutation(() => OfficeTitle, { name: 'officeAddTitle' })
  @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
  @SetMetadata(ServiceKeys.UserType, [UserType.SYSTEM_USER])
  async officeAddTitle(
    @Args('arguments', { nullable: false }) args: OfficeTitleArgs,
    @RequesterId() requesterId: string,
  ): Promise<OfficeTitle> {
    const existedTitle = await OfficeTitle.findOne({
      where: {
        name: args.name
      }
    })

    if (existedTitle) {
      throw OfficeError.OfficeTitleIsExisted
    }

    const title = OfficeTitle.create({
      name: args.name,
      note: args.note,
      createdBy: requesterId,
      updatedBy: requesterId
    })

    return title.save()
  }

  @Query(_return => OfficeTitleResponse, { name: "officeGetTitles" })
  @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
  async officeGetTitles(
    @Args("filter", { nullable: true }) filter: OfficeTitleFilter
  ): Promise<OfficeTitleResponse> {
    const [list, count] = await this.profileService.getTitleList(filter)

    return {
      total: count,
      count: list.length,
      titles: list
    }
  }

  @Mutation(() => OfficeTitle, { name: 'officeEditTitle' })
  @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
  @SetMetadata(ServiceKeys.UserType, [UserType.SYSTEM_USER])
  async officeEditTitle(
    @Args('arguments', { nullable: false }) args: EditOfficeTitleArgs,
    @RequesterId() requesterId: string,
  ): Promise<OfficeTitle> {
    const existedTitle = await OfficeTitle.findOne({
      where: {
        id: args.id
      }
    })

    if (!existedTitle) {
      throw OfficeError.OfficeTitleNotExisted
    }

    if (args.name && args.name !== existedTitle.name) {
      const existedName = await OfficeTitle.findOne({
        where: {
          name: args.name
        }
      })
      if (existedName) {
        throw OfficeError.OfficeTitleIsExisted
      }
      existedTitle.name = args.name
    }
    if (args.note !== undefined) existedTitle.note = args.note
    existedTitle.updatedBy = requesterId
    return existedTitle.save()
  }

  @Mutation(_return => OfficeTitle, { name: "officeRemoveTitle" })
  @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
  @SetMetadata(ServiceKeys.UserType, [UserType.SYSTEM_USER])
  async officeRemoveTitle(
    @Args("id") id: string,
    @RequesterId() requesterId: string,
  ): Promise<OfficeTitle> {
    const existedTitle = await OfficeTitle.findOne({
      where: { id: id }
    })

    if (!existedTitle) throw OfficeError.OfficeTitleNotExisted

    //Xóa liên kết
    await UserDepartment.update({
      titleId: id
    }, {
      titleId: null
    })

    existedTitle.updatedBy = requesterId
    await existedTitle.softRemove()

    return existedTitle
  }

  // TODO: need refactor
  @Mutation(_type => BulkUpsertTitleResponse, { nullable: true, name: "officeTitleBulkUpsert" })
  @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
  @SetMetadata(ServiceKeys.UserType, [UserType.SYSTEM_USER])
  async officeTitleBulkUpsert(
    @Args('titles', { type: () => [UpsertTitleArgs] }) titles: UpsertTitleArgs[],
    @RequesterId() requesterId: string,
  ): Promise<BulkUpsertTitleResponse> {
    try {
      const response: UpsertTitleResponse[] = []
      const existedNames: String[] = []
      const upsertTitles: OfficeTitle[] = []
      for (const input of titles) {
        if (!input.name) {
          response.push({ ...input, errorMessage: 'Vui lòng không để trống trường bắt buộc' })
          continue
        }

        const existedTitleName = await OfficeTitle.findOne({
          where: {
            name: input.name
          }
        })

        if (input.code) {
          // update
          const existedTitle = await OfficeTitle.findOne({
            where: { code: input.code }
          })

          if (!existedTitle) {
            // response.push({ ...input, errorMessage: 'Mã không tồn tại' })
            // insert
            if (existedTitleName || existedNames.includes(input.name)) {
              response.push({ ...input, errorMessage: 'Chức vụ đã tồn tại' })
              continue
            }

            upsertTitles.push(OfficeTitle.create({
              name: input.name,
              code: input.code,
              createdBy: requesterId,
              updatedBy: requesterId
            }))
            response.push({ ...input, errorMessage: 'Tạo mới thành công' })
            existedNames.push(input.name)
            continue
          }

          if ((existedTitleName && existedTitleName.code !== existedTitle.code) || existedNames.includes(input.name)) {
            response.push({ ...input, errorMessage: 'Chức vụ đã tồn tại' })
            continue
          }

          existedTitle.name = input.name
          existedTitle.updatedBy = requesterId
          upsertTitles.push(existedTitle)
          response.push({ ...input, errorMessage: 'Cập nhật thành công' })
        } else {
          // insert
          if (existedTitleName || existedNames.includes(input.name)) {
            response.push({ ...input, errorMessage: 'Chức vụ đã tồn tại' })
            continue
          }

          upsertTitles.push(OfficeTitle.create({
            name: input.name,
            createdBy: requesterId,
            updatedBy: requesterId
          }))
          response.push({ ...input, errorMessage: 'Tạo mới thành công' })
          existedNames.push(input.name)
        }
      }

      for (const iterator of upsertTitles) {
        await iterator.save()
      }

      return {
        total: response.length,
        count: response.length,
        records: response
      }
    } catch (error) {
      console.log(`Bulk upsert office title has error: ${error}`)
      throw error
    }
  }

  @Mutation(() => String, { name: "profileRemoveBlockField" })
  @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
  @SetMetadata(ServiceKeys.UserType, [UserType.SYSTEM_USER])
  async profileRemoveBlockField(
      @Args("id") id: string,
      @RequesterId() requesterId: string
  ) {

    return await this.profileService.profileRemoveBlockField(id, requesterId)
  }
}