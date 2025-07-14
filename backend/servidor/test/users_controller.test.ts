import { Request, Response } from 'express';
import { UsersController } from '../src/users_controller';
import { SupabaseWrapper } from '../src/supabase_wrapper';

// Mock do SupabaseWrapper
jest.mock('../src/supabase_wrapper');

describe('UsersController', () => {
  let mockRequest: Partial<Request>;
  let mockResponse: Partial<Response>;
  let mockSupabaseChain: any; // Declarar como any para quebrar a inferência de tipo circular

  beforeEach(() => {
    mockRequest = {};
    mockResponse = {
      status: jest.fn().mockReturnThis(),
      json: jest.fn(),
    };

    // Mock da cadeia de chamadas do Supabase
    mockSupabaseChain = {
      from: jest.fn(() => mockSupabaseChain),
      select: jest.fn(() => mockSupabaseChain),
      eq: jest.fn(() => mockSupabaseChain),
      insert: jest.fn(() => mockSupabaseChain),
      update: jest.fn(() => mockSupabaseChain),
      single: jest.fn(),
    };

    // Configura o mock para SupabaseWrapper.get()
    (SupabaseWrapper.get as jest.Mock).mockReturnValue(mockSupabaseChain);
  });

  describe('checkUserExists', () => {
    it('should return 400 if email is missing', async () => {
      mockRequest.query = {};

      await UsersController.routes.exists!.value(mockRequest as Request, mockResponse as Response);

      expect(mockResponse.status).toHaveBeenCalledWith(400);
      expect(mockResponse.json).toHaveBeenCalledWith({ error: 'Missing email' });
    });

    it('should return 404 if user not found', async () => {
      mockRequest.query = { email: 'nonexistent@example.com' };
      // Configura o mock para o retorno de eq()
      mockSupabaseChain.eq.mockResolvedValueOnce({
        data: [],
        error: null,
      });

      await UsersController.routes.exists!.value(mockRequest as Request, mockResponse as Response);

      expect(mockResponse.status).toHaveBeenCalledWith(404);
      expect(mockResponse.json).toHaveBeenCalledWith({ error: 'User not found' });
    });

    it('should return 200 and user data if user found', async () => {
      const userData = { id: 1, email: 'test@example.com' };
      mockRequest.query = { email: 'test@example.com' };
      // Configura o mock para o retorno de eq()
      mockSupabaseChain.eq.mockResolvedValueOnce({
        data: [userData],
        error: null,
      });

      await UsersController.routes.exists!.value(mockRequest as Request, mockResponse as Response);

      expect(mockResponse.status).toHaveBeenCalledWith(200);
      expect(mockResponse.json).toHaveBeenCalledWith(userData);
    });

    it('should return 500 if there is a Supabase error', async () => {
      mockRequest.query = { email: 'test@example.com' };
      // Configura o mock para o retorno de eq()
      mockSupabaseChain.eq.mockResolvedValueOnce({
        data: null,
        error: { message: 'Database error' },
      });

      await UsersController.routes.exists!.value(mockRequest as Request, mockResponse as Response);

      expect(mockResponse.status).toHaveBeenCalledWith(500);
      expect(mockResponse.json).toHaveBeenCalledWith({ error: 'Error checking user exists' });
    });
  });

  describe('createUser', () => {
    it('should return 400 if required fields are missing', async () => {
      mockRequest.body = {};

      await UsersController.routes.create!.value(mockRequest as Request, mockResponse as Response);

      expect(mockResponse.status).toHaveBeenCalledWith(400);
      expect(mockResponse.json).toHaveBeenCalledWith({ error: 'Missing required fields' });
    });

    it('should return 200 and user data if user created successfully', async () => {
      const newUserData = {
        email: 'newuser@example.com',
        name: 'New User',
        phone_number: '1234567890',
        id_escola: 1,
      };
      mockRequest.body = newUserData;
      // Mock da cadeia insert().select().single()
      mockSupabaseChain.insert.mockReturnValueOnce({
        select: jest.fn(() => ({
          single: jest.fn().mockResolvedValueOnce({
            data: newUserData,
            error: null,
          }),
        })),
      });

      await UsersController.routes.create!.value(mockRequest as Request, mockResponse as Response);

      expect(mockResponse.status).toHaveBeenCalledWith(200);
      expect(mockResponse.json).toHaveBeenCalledWith(newUserData);
    });

    it('should return 500 if there is a Supabase error during creation', async () => {
      mockRequest.body = {
        email: 'newuser@example.com',
        name: 'New User',
        phone_number: '1234567890',
        id_escola: 1,
      };
      // Mock da cadeia insert().select().single() com erro
      mockSupabaseChain.insert.mockReturnValueOnce({
        select: jest.fn(() => ({
          single: jest.fn().mockResolvedValueOnce({
            data: null,
            error: { message: 'Database error' },
          }),
        })),
      });

      await UsersController.routes.create!.value(mockRequest as Request, mockResponse as Response);

      expect(mockResponse.status).toHaveBeenCalledWith(500);
      expect(mockResponse.json).toHaveBeenCalledWith({ error: 'Error creating user' });
    });
  });

  describe('updateUser', () => {
    it('should return 400 if user ID is missing', async () => {
      mockRequest.body = {};

      await UsersController.routes.update!.value(mockRequest as Request, mockResponse as Response);

      expect(mockResponse.status).toHaveBeenCalledWith(400);
      expect(mockResponse.json).toHaveBeenCalledWith({ error: 'Missing user ID' });
    });

    it('should return 400 if no fields to update', async () => {
      mockRequest.body = { id_user: 1 };

      await UsersController.routes.update!.value(mockRequest as Request, mockResponse as Response);

      expect(mockResponse.status).toHaveBeenCalledWith(400);
      expect(mockResponse.json).toHaveBeenCalledWith({ error: 'No fields to update' });
    });

    it('should return 200 and updated user data if user updated successfully', async () => {
      const updatedUserData = { id_user: 1, nome_completo: 'Updated Name' };
      mockRequest.body = updatedUserData;
      // Mock da cadeia update().eq().select().single()
      mockSupabaseChain.update.mockReturnValueOnce({
        eq: jest.fn(() => ({
          select: jest.fn(() => ({
            single: jest.fn().mockResolvedValueOnce({
              data: updatedUserData,
              error: null,
            }),
          })),
        })),
      });

      await UsersController.routes.update!.value(mockRequest as Request, mockResponse as Response);

      expect(mockResponse.status).toHaveBeenCalledWith(200);
      expect(mockResponse.json).toHaveBeenCalledWith(updatedUserData);
    });

    it('should return 500 if there is a Supabase error during update', async () => {
      mockRequest.body = { id_user: 1, nome_completo: 'Updated Name' };
      // Mock da cadeia update().eq().select().single() com erro
      mockSupabaseChain.update.mockReturnValueOnce({
        eq: jest.fn(() => ({
          select: jest.fn(() => ({
            single: jest.fn().mockResolvedValueOnce({
              data: null,
              error: { message: 'Database error' },
            }),
          })),
        })),
      });

      await UsersController.routes.update!.value(mockRequest as Request, mockResponse as Response);

      expect(mockResponse.status).toHaveBeenCalledWith(500);
      expect(mockResponse.json).toHaveBeenCalledWith({ error: 'Error updating user' });
    });
  });
});