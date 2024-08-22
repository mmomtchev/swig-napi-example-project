import mocha from 'eslint-plugin-mocha';
import globals from 'globals';
import typescriptEslint from '@typescript-eslint/eslint-plugin';
import tsParser from '@typescript-eslint/parser';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import js from '@eslint/js';
import { FlatCompat } from '@eslint/eslintrc';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const compat = new FlatCompat({
    baseDirectory: __dirname,
    recommendedConfig: js.configs.recommended,
    allConfig: js.configs.all
});

export default [{
    ignores: ['test/browser/build/*'],
}, ...compat.extends('eslint:recommended'), {
    plugins: {
        mocha,
    },

    languageOptions: {
        globals: {
            ...globals.mocha,
            ...globals['shared-node-browser'],
            __karma__: true,
            process: true,
        },

        ecmaVersion: 2020,
        sourceType: 'module',
    },

    rules: {
        semi: [2, 'always'],
        quotes: ['error', 'single'],
    },
}, ...compat.extends(
    'eslint:recommended',
    'plugin:@typescript-eslint/eslint-recommended',
    'plugin:@typescript-eslint/recommended',
).map(config => ({
    ...config,
    files: ['test/*.ts'],
})), {
    files: ['test/*.ts'],

    plugins: {
        '@typescript-eslint': typescriptEslint,
    },

    languageOptions: {
        parser: tsParser,
    },

    rules: {
        '@typescript-eslint/ban-ts-comment': 'off',
    },
}, {
    files: ['**/*.cjs'],

    languageOptions: {
        ecmaVersion: 2015,
        sourceType: 'commonjs',
    },
}, {
    files: ['test/browser/*.js'],

    languageOptions: {
        globals: {
            ...globals.browser,
        },
    },
}];
