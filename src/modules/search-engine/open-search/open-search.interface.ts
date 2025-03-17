export interface IndexDefinition {
    // index: string; // Name of the index
    mappings: {
        properties: Record<string, any>; // Field mappings
    };
    settings?: Record<string, any>; // Optional index settings
}
