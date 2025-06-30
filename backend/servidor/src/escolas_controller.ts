import { Request, Response } from 'express';
import { EndpointController, RequestType } from './interfaces';
import { Pair, Utils } from './utils';
import { SupabaseWrapper } from './supabase_wrapper';

const logInfo = (message: string, context?: any) => {
    Utils.info(`[${EscolasController.name}] ${message}`, context);
}

const logError = (message: string, context?: any) => {
    Utils.error(`[${EscolasController.name}] ${message}`, context);
}

export const EscolasController: EndpointController = {
    name: 'escolas',
    routes: {
        'list': new Pair<RequestType, (req: Request, res: Response) => Promise<Response | void>>(RequestType.GET, listEscolas),
    }
}

async function listEscolas(req: Request, res: Response): Promise<Response | void> {
    logInfo("Listing escolas");

    const escolas = await SupabaseWrapper.get().from('escolas').select('*');

    if (escolas.error) {
        logError("Error listing escolas", escolas.error);
        return res.status(500).json({ error: "Error listing escolas" });
    }

    return res.status(200).json(escolas.data);
}
