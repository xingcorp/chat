import * as dotenv from 'dotenv';

dotenv.config();
import * as Typesense from "typesense"
import { CollectionSchema } from "typesense/src/Typesense/Collection";
import type { SearchParams, SearchParamsWithPreset } from "typesense/lib/Typesense/Documents";
import { DocumentsExportParameters } from "typesense/src/Typesense/Documents";
import { CollectionCreateSchema } from "typesense/src/Typesense/Collections";

export const searchEngineClient = new Typesense.Client({
    nodes: [{
        host: process.env.TYPESENSE_HOST,
        port: parseInt(process.env.TYPESENSE_PORT),
        protocol: process.env.TYPESENSE_PROTOCAL
    }],
    apiKey: process.env.TYPESENSE_API_KEY,
    connectionTimeoutSeconds: 5
})

export const searchEngineImportClient = new Typesense.Client({
    nodes: [{
        host: process.env.TYPESENSE_HOST,
        port: parseInt(process.env.TYPESENSE_PORT),
        protocol: process.env.TYPESENSE_PROTOCAL
    }],
    apiKey: process.env.TYPESENSE_API_KEY,
    connectionTimeoutSeconds: 5 * 60
})

export async function typesenseCheckCreateCollectionDefault(name: string) {
    let collection: CollectionSchema

    try {
        collection = await searchEngineClient.collections(name).retrieve()
    } catch (e) {
        collection = await searchEngineClient.collections().create({
            "name": name,
            "fields": [
                {
                    "name": ".*",
                    "type": "auto",
                }
            ]
        })
    }

    return collection
}


export async function typesenseCheckCreateCollection(schema: CollectionCreateSchema) {
    let collection: CollectionSchema

    try {
        collection = await searchEngineClient.collections(schema.name).retrieve()
    } catch (e) {
        collection = await searchEngineClient.collections().create(schema)
    }

    return collection
}

export async function typesenseDocumentCreate(collection: string, document: any) {
    try {
        return searchEngineClient.collections(collection).documents().create(document)
    } catch (e) {
        console.log(e)
    }
}

export async function typesenseDocumentUpsert(collection: string, document: any) {
    try {
        return searchEngineClient.collections(collection).documents().upsert(document)
    } catch (e) {
        console.log(e)
    }
}

export async function typesenseDocumentEmplace(collection: string, document: any) {
    try {
        return searchEngineClient.collections(collection).documents().import([document], {action: 'emplace'})
    } catch (e) {
        console.log('typesenseDocumentEmplace', e)
    }
}

export async function typesenseDocumentExport(collection: string) {
    try {
        return searchEngineClient.collections(collection).documents().export()
    } catch (e) {
        console.log(e)
    }
}

export async function typesenseDocumentSearch(collection: string, searchParameters: SearchParams | SearchParamsWithPreset) {
    try {
        return searchEngineClient.collections(collection).documents().search(searchParameters)
    } catch (e) {
        console.log('typesenseDocumentSearch', e)
    }
}

export async function typesenseDocumentExportBy(collection: string, options?: DocumentsExportParameters) {
    try {
        return searchEngineClient.collections(collection).documents().export(options)
    } catch (e) {
        console.log(e)
    }
}

export async function typesenseCollectionRemove(collection: string) {
    try {
        console.log('remove collection', collection)
        return searchEngineClient.collections(collection).delete()
    } catch (e) {
        console.log('typesenseCollectionRemove', e)
    }
}

export async function typesenseCheckAndGetDocument(collection: string, documentId: string) {
    try {
        const doc = await searchEngineClient.collections(collection).documents(documentId).retrieve()
        return doc
    } catch (e) {
        return false
    }
}
