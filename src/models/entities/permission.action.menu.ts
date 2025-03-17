import { Base } from '@models/office.base'
import { ObjectType, Field } from '@nestjs/graphql'
import { Entity, Column, Unique } from 'typeorm'

@ObjectType()
@Entity('office-permission-action-menus')
export class OfficePermissionActionMenu extends Base {
  @Column({ nullable: false })
  actionId: string

  @Column({ nullable: false })
  menuId: string
}