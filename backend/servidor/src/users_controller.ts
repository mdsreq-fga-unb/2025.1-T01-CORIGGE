import { Request, Response } from 'express';
import { EndpointController, RequestType } from './interfaces';
import { Pair, Utils } from './utils';
import { SupabaseWrapper } from './supabase_wrapper';


const logInfo = (endpoint: string, message: string, context?: any) => {
    Utils.info(`[${UsersController.name}][${endpoint}] ${message}`, context);
}

const logError = (endpoint: string, message: string, context?: any) => {
    Utils.error(`[${UsersController.name}][${endpoint}] ${message}`, context);
}

export const UsersController: EndpointController = {
    name: 'users',
    routes: {
        'create': new Pair<RequestType, (req: Request, res: Response) => Promise<Response | void>>(RequestType.POST, createUser),
        'exists': new Pair<RequestType, (req: Request, res: Response) => Promise<Response | void>>(RequestType.GET, checkUserExists),
        'update': new Pair<RequestType, (req: Request, res: Response) => Promise<Response | void>>(RequestType.PUT, updateUser),
    }
}

async function checkUserExists(req: Request, res: Response): Promise<Response | void> {
    logInfo('exists', `Checking user exists ${req.query.email}`);

    if (!req.query.email) {
        logError('exists', "Missing email");
        return res.status(400).json({ error: "Missing email" });
    }

    const user = await SupabaseWrapper.get().from('users').select('*').eq('email', req.query.email);

    if (user.error) {
        logError('exists', "Error checking user exists", user.error);
        return res.status(500).json({ error: "Error checking user exists" });
    }

    if (user.data.length === 0) {
        logInfo('exists', "User not found");
        return res.status(404).json({ error: "User not found" });
    }

    logInfo('exists', "User found", user.data[0]);

    return res.status(200).json(user.data[0]);
}




async function createUser(req: Request, res: Response): Promise<Response | void> {
    logInfo('create', "Creating user");

    if (!req.body.email || !req.body.nome_completo || !req.body.phone_number || !req.body.id_escola) {
        logError('create', "Missing required fields: " + JSON.stringify(req.body));
        return res.status(400).json({ error: "Missing required fields" });
    }

    const user = await SupabaseWrapper.get().from('users').insert({
        email: req.body.email,
        nome_completo: req.body.nome_completo,
        phone_number: req.body.phone_number,
        id_escola: req.body.id_escola,
    }).select().single();

    if (user.error) {
        logError('create', "Error creating user", user.error);
        return res.status(500).json({ error: "Error creating user" });
    }

    logInfo('create', "User created", user);
    return res.status(200).json(user.data);
}

async function updateUser(req: Request, res: Response): Promise<Response | void> {
    logInfo('update', "Updating user");

    if (!req.body.id_user) {
        logError('update', "Missing user ID");
        return res.status(400).json({ error: "Missing user ID" });
    }

    const updateData: any = {};

    if (req.body.nome_completo) updateData.nome_completo = req.body.nome_completo;
    if (req.body.phone_number) updateData.phone_number = req.body.phone_number;
    if (req.body.id_escola) updateData.id_escola = req.body.id_escola;

    if (Object.keys(updateData).length === 0) {
        logError('update', "No fields to update");
        return res.status(400).json({ error: "No fields to update" });
    }

    const user = await SupabaseWrapper.get()
        .from('users')
        .update(updateData)
        .eq('id_user', req.body.id_user)
        .select()
        .single();

    if (user.error) {
        logError('update', "Error updating user", user.error);
        return res.status(500).json({ error: "Error updating user" });
    }

    logInfo('update', "User updated", user.data);
    return res.status(200).json(user.data);
}








