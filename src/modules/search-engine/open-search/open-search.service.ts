
import { Injectable, Inject } from '@nestjs/common';
import { Client } from '@opensearch-project/opensearch';
import { ConfigOpenSearchModuleOptions } from './open-search.module';
import { LoggerService } from '@core/common/logger.service';
import { MapIndexOpenSearch } from './open-search.index';

@Injectable()
export class OpenSearchService<T> {
  private readonly indexName: string
  private logger = new LoggerService(OpenSearchService.name);
  private documentProperties: string[]

  constructor(
    @Inject('OPENSEARCH_CLIENT') private readonly openSearchClient: Client,
    @Inject('CONFIG_OPTIONS') private options: ConfigOpenSearchModuleOptions) {
    this.indexName = options.indexName;
    this.initializeIndex().then().catch(error => this.logger.error(`Initialize Index Name ${this.indexName}`, error));
  }

  async initializeIndex() {
    const index = this.indexName;
    if (!MapIndexOpenSearch[index]) throw new Error(`Index "${index}" haven't defined in MapIndexOpenSearch`);
    this.documentProperties = Object.keys(MapIndexOpenSearch[index].mappings.properties);

    const exists = await this.openSearchClient.indices.exists({ index });
    if (!exists.body) {
      await this.openSearchClient.indices.create({
        index,
        body: MapIndexOpenSearch[index]
      });
      this.logger.log(`Index "${index}" created successfully.`);
    } else {
      this.logger.log(`Index "${index}" already exists.`);
    }
  }

  async indexDocument(id: string, document: T) {
    const formattedDoc = Object.keys(document)
      .filter(key => this.documentProperties.includes(key))
      .reduce((obj, key) => {
        obj[key] = document[key];
        return obj;
      }, {});

    const response = await this.openSearchClient.index({
      index: this.indexName,
      id,
      body: formattedDoc,
    });
    return response.body;
  }

  async deleteDocument(messageId: string) {
    try {
      await this.openSearchClient.delete({
        index: this.indexName,
        id: messageId,
      });
      return true;
    } catch (error) {
      // Ignore 404 errors - document already deleted or doesn't exist
      if (error?.meta?.statusCode === 404) {
        return true;
      }
      this.logger.error('deleteDocument error:', { messageId, error });
      throw error;
    }
  }

  async search(payload: Record<string, any>) {
    this.logger.log('search', JSON.stringify(payload));
    const response = await this.openSearchClient.search({
      index: this.indexName,
      body: payload,
    });
    return response.body.hits.hits;
  }
}
