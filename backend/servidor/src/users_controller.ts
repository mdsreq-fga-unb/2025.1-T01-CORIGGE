import { Request, Response } from 'express';
import { EndpointController, RequestType } from './interfaces';
import { Pair, Utils } from './utils';
import { SupabaseWrapper } from './supabase_wrapper';


const logInfo = (message: string, context?: any) => {
    Utils.info(`[${UsersController.name}] ${message}`, context);
}

const logError = (message: string, context?: any) => {
    Utils.error(`[${UsersController.name}] ${message}`, context);
}

export const UsersController: EndpointController = {
    name: 'users',
    routes: {
        'create': new Pair<RequestType, (req: Request, res: Response) => Promise<Response | void>>(RequestType.POST, createUser),
        'exists': new Pair<RequestType, (req: Request, res: Response) => Promise<Response | void>>(RequestType.GET, checkUserExists),
    }
}

async function checkUserExists(req: Request, res: Response): Promise<Response | void> {
    logInfo("Checking user exists");

    const user = await SupabaseWrapper.get().from('users').select('*').eq('email', req.body.email);

    if (user.error) {
        logError("Error checking user exists", user.error);
        return res.status(500).json({ error: "Error checking user exists" });
    }

    if (user.data.length === 0) {
        return res.status(404).json({ error: "User not found" });
    }

    return res.status(200).json(user.data[0]);
}




async function createUser(req: Request, res: Response): Promise<Response | void> {
    logInfo("Creating user");

    if (!req.body.email || !req.body.name || !req.body.phone_number) {
        logError("Missing required fields");
        return res.status(400).json({ error: "Missing required fields" });
    }

    const user = await SupabaseWrapper.get().from('users').insert({
        email: req.body.email,
        name: req.body.name,
        phone_number: req.body.phone_number,
    }).select().single();

    if (user.error) {
        logError("Error creating user", user.error);
        return res.status(500).json({ error: "Error creating user" });
    }

    logInfo("User created", user);
    return res.status(200).json(user.data);
}








