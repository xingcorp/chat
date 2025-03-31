import { Resolver, Query } from '@nestjs/graphql'

@Resolver()
export class AboutResolver {
  @Query(() => String)
  async boujour(): Promise<string> {
    return 'This is Sharitek Customer Relationship Management service'
  }

  @Query(() => String)
  async license(): Promise<string> {
    return 'Copyright © 2021 Sharitek. All rights reserved.'
  }
}
