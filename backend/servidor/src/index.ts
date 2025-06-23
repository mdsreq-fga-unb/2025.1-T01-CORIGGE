import express, { Request, Response, NextFunction } from 'express';
import cors from 'cors';
import { createClient } from '@supabase/supabase-js';
import { environment, validateEnvironment, PORT, SUPABASE_URL, SUPABASE_ANON_KEY, CORS_ORIGIN } from './environment';
import logger from './logger';

// Validate environment variables on startup
validateEnvironment();

// Initialize Express app
const app = express();

// Initialize Supabase client
const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY);

// Middleware
app.use(cors({
    origin: CORS_ORIGIN,
    credentials: true
}));

app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true }));

// Request logging middleware
app.use((req: Request, res: Response, next: NextFunction) => {
    logger.http(`${req.method} ${req.path} - IP: ${req.ip}`);
    next();
});

// Health check endpoint
app.get('/health', (req: Request, res: Response) => {
    logger.debug('Health check endpoint called');
    res.status(200).json({
        status: 'OK',
        timestamp: new Date().toISOString(),
        environment: environment.NODE_ENV,
        supabaseConnected: !!SUPABASE_URL && !!SUPABASE_ANON_KEY
    });
});

// API routes
app.get('/api', (req: Request, res: Response) => {
    logger.debug('API root endpoint called');
    res.json({
        message: 'Welcome to the API',
        version: '1.0.0',
        endpoints: {
            health: '/health',
            api: '/api'
        }
    });
});

// Example Supabase endpoint - you can modify this as needed
app.get('/api/test-supabase', async (req: Request, res: Response): Promise<void> => {
    try {
        logger.info('Testing Supabase connection');
        // This is just a test to verify Supabase connection
        // You can replace this with actual database operations
        const { data, error } = await supabase.auth.getSession();

        if (error) {
            logger.error('Supabase test error:', { error: error.message });
            res.status(500).json({
                error: 'Supabase connection test failed',
                details: error.message
            });
            return;
        }

        logger.info('Supabase connection test successful');
        res.json({
            message: 'Supabase connection successful',
            connected: true
        });
    } catch (error) {
        logger.error('Supabase test error:', { error });
        res.status(500).json({
            error: 'Failed to test Supabase connection',
            details: error instanceof Error ? error.message : 'Unknown error'
        });
    }
});

// 404 handler
app.use('*', (req: Request, res: Response) => {
    logger.warn(`Route not found: ${req.method} ${req.originalUrl}`);
    res.status(404).json({
        error: 'Route not found',
        path: req.originalUrl,
        method: req.method
    });
});

// Global error handler
app.use((error: Error, req: Request, res: Response, next: NextFunction) => {
    logger.error('Global error handler:', {
        error: error.message,
        stack: error.stack,
        path: req.path,
        method: req.method
    });

    res.status(500).json({
        error: 'Internal server error',
        message: environment.NODE_ENV === 'development' ? error.message : 'Something went wrong',
        ...(environment.NODE_ENV === 'development' && { stack: error.stack })
    });
});

// Start server
const server = app.listen(PORT, () => {
    logger.info(`🚀 Server running on port ${PORT}`);
    logger.info(`📊 Health check: http://localhost:${PORT}/health`);
    logger.info(`🔗 API: http://localhost:${PORT}/api`);
    logger.info(`🌍 Environment: ${environment.NODE_ENV}`);
    logger.info(`🔌 Supabase URL: ${SUPABASE_URL ? 'Configured' : 'Not configured'}`);
});

// Graceful shutdown
process.on('SIGTERM', () => {
    logger.info('SIGTERM received, shutting down gracefully');
    server.close(() => {
        logger.info('Process terminated');
        process.exit(0);
    });
});

process.on('SIGINT', () => {
    logger.info('SIGINT received, shutting down gracefully');
    server.close(() => {
        logger.info('Process terminated');
        process.exit(0);
    });
});

export { app, supabase }; 