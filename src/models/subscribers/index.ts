import * as fs from 'fs';
import * as path from 'path';

const subscribers: Record<string, any> = {};

// Recursively read all files in the directory
function loadSubscribers(dir: string) {
    fs.readdirSync(dir).forEach(file => {
        const fullPath = path.join(dir, file);
        if (fs.statSync(fullPath).isDirectory()) {
            loadSubscribers(fullPath); // Recursive call for nested folders
        } else if (file.endsWith('.subscriber.ts') || file.endsWith('.subscriber.js')) {
            const module = require(fullPath);
            Object.assign(subscribers, module);
        }
    });
}

// Start loading from the `subscribers` directory
loadSubscribers(__dirname);

export = subscribers;
