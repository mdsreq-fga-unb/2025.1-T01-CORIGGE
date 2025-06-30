export class Pair<K, V> {
    key: K;
    value: V;

    constructor(key: K, value: V) {
        this.key = key;
        this.value = value;
    }
}

export const Utils = {
    /**
     * Returns a formatted timestamp for logging
     */
    getTimestamp(): string {
        return new Date().toISOString();
    },

    /**
     * Logs an informational message
     * @param message The message to log
     * @param context Optional context object to log
     */
    info(message: string, context?: any): void {
        const timestamp = this.getTimestamp();
        console.log(`\x1b[36m[INFO]\x1b[0m [${timestamp}] ${message}`);
        if (context) {
            console.log('\x1b[36m[Context]\x1b[0m', context);
        }
    },

    /**
     * Logs a warning message
     * @param message The warning message to log
     * @param context Optional context object to log
     */
    warning(message: string, context?: any): void {
        const timestamp = this.getTimestamp();
        console.log(`\x1b[33m[WARNING]\x1b[0m [${timestamp}] ${message}`);
        if (context) {
            console.log('\x1b[33m[Context]\x1b[0m', context);
        }
    },

    /**
     * Logs an error message
     * @param message The error message to log
     * @param error Optional error object to log
     * @param context Optional context object to log
     */
    error(message: string, error?: Error, context?: any): void {
        const timestamp = this.getTimestamp();
        console.error(`\x1b[31m[ERROR]\x1b[0m [${timestamp}] ${message}`);
        if (error) {
            console.error('\x1b[31m[Error Details]\x1b[0m', error);
        }
        if (context) {
            console.error('\x1b[31m[Context]\x1b[0m', context);
        }
    }
};