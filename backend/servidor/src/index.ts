import { createClient } from '@supabase/supabase-js'
import { SupabaseWrapper } from './supabase_wrapper'
import expressws from "express-ws";

import express, { Express, NextFunction, Request, Response } from 'express';
import fileUpload from 'express-fileupload';

import dotenv from "dotenv";
import { Utils } from './utils';
import bodyParser from 'body-parser';
import cors from "cors";
import { UsersController } from './users_controller';
import logger from './logger';
import { environment, SUPABASE_URL } from './environment';
import { EndpointController, RequestType } from './interfaces';
import { EscolasController } from './escolas_controller';


dotenv.config();

SupabaseWrapper.init();

const router = express.Router();

const controllers: EndpointController[] = [
    UsersController,
    EscolasController
];

controllers.forEach(controller => {
    Object.keys(controller.routes).forEach(route_name => {
        const route = controller.routes[route_name];
        const method = route!.key;
        const callback = route!.value;

        switch (method) {
            case RequestType.GET:
                router.get(`/${controller.name}/${route_name}`, async (req: Request, res: Response) => {
                    try {
                        await callback(req, res);
                    } catch (error) {
                        res.status(500).json({ error: 'Internal server error' });
                    }
                });
                break;
            case RequestType.POST:
                router.post(`/${controller.name}/${route_name}`, async (req: Request, res: Response) => {
                    try {
                        await callback(req, res);
                    } catch (error) {
                        res.status(500).json({ error: 'Internal server error' });
                    }
                });
                break;
            case RequestType.PUT:
                router.put(`/${controller.name}/${route_name}`, async (req: Request, res: Response) => {
                    try {
                        await callback(req, res);
                    } catch (error) {
                        res.status(500).json({ error: 'Internal server error' });
                    }
                });
                break;
            default:
                break;
        }
    });
});

const app: Express = express();

expressws(app);

app.use(fileUpload())
app.use(bodyParser.json({ limit: 500 * 1024 * 1024, }));
app.use(function (req, res, next) {
    res.header("Access-Control-Allow-Origin", "*");
    res.header("Access-Control-Allow-Headers", "Origin, X-Requested-With, Content-Type, Accept, Authorization");
    next();
});


app.use(router);






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

const PORT = process.env.PORT ?? 5423;

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

export { app }; 