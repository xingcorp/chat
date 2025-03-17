import { Module } from '@nestjs/common';
import { TypesenseService } from './typesense.service';
import { AlgoliaService } from './algolia.service';

@Module({
  providers: [
    {
      provide: 'SearchEngineService',
      useClass: TypesenseService
    },
    {
      provide: 'SearchEngineFirebaseService',
      useClass: AlgoliaService
    },
  ],
  exports: [
    {
      provide: 'SearchEngineService',
      useClass: TypesenseService
    },
    {
      provide: 'SearchEngineFirebaseService',
      useClass: AlgoliaService
    },
  ]
})
export class SearchEngineModule { }
