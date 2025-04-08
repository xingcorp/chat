import { ModelModule } from '@models/model.module';
import { Global, Module, DynamicModule } from '@nestjs/common';
import * as fs from 'fs';
import * as path from 'path';

@Global()
@Module({
    imports: [ModelModule],
})
export class ValidatorModule {
    static async register(): Promise<DynamicModule> {
        const validators = await ValidatorModule.loadConstraintsFromFolder(path.join(__dirname, 'db'));

        return {
            module: ValidatorModule,
            providers: validators,
            exports: validators,
        };
    }

    private static async loadConstraintsFromFolder(dir: string): Promise<any[]> {
        const constraints: any[] = [];
        const files = fs.readdirSync(dir, { withFileTypes: true });

        for (const file of files) {
            const fullPath = path.join(dir, file.name);

            if (file.isDirectory()) {
                const subConstraints = await ValidatorModule.loadConstraintsFromFolder(fullPath);
                constraints.push(...subConstraints);
            } else if (file.name.endsWith('.js')) {
                const module = await import(fullPath);

                // Only keep classes decorated with `@ValidatorConstraint`
                Object.values(module).forEach((exported) => {
                    if (typeof exported === 'function') {
                        constraints.push(exported);
                    }
                });
            }
        }
        return constraints;
    }
}
