import { DynamicModule, Module } from '@nestjs/common';
import { Client } from '@opensearch-project/opensearch';
import { OpenSearchService } from './open-search.service';

export interface ConfigOpenSearchModuleOptions {
  indexName: string;
}

@Module({})
export class OpenSearchModule {
  static register(options: ConfigOpenSearchModuleOptions): DynamicModule {
    return {
      module: OpenSearchModule,
      providers: [
        {
          provide: 'CONFIG_OPTIONS',
          useValue: options,
        },
        {
          provide: 'OPENSEARCH_CLIENT',
          useFactory: () => {
            const proxyUrl = `${process.env.PROXY_PROTOCOL}://${process.env.PROXY_USER}:${process.env.PROXY_PASS}@${process.env.PROXY_HOST}:${process.env.PROXY_PORT}`;

            return new Client({
              node: process.env.OPEN_SEARCH_NODE,
              auth: {
                username: process.env.OPEN_SEARCH_USERNAME,
                password: process.env.OPEN_SEARCH_PASSWORD,
              },
              proxy: proxyUrl
            });
          },
        },
        OpenSearchService,
      ],
      exports: [OpenSearchService],
    };
  }
}
