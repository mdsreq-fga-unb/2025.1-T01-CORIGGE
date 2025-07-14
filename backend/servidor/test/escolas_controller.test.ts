import { Request, Response } from 'express';
import { EscolasController } from '../src/escolas_controller';
import { SupabaseWrapper } from '../src/supabase_wrapper';

// Mock do SupabaseWrapper
jest.mock('../src/supabase_wrapper');

describe('EscolasController', () => {
  let mockRequest: Partial<Request>;
  let mockResponse: Partial<Response>;
  let mockSupabaseChain: any;

  beforeEach(() => {
    mockRequest = {};
    mockResponse = {
      status: jest.fn().mockReturnThis(),
      json: jest.fn(),
    };

    mockSupabaseChain = {
      from: jest.fn(() => mockSupabaseChain),
      select: jest.fn(() => mockSupabaseChain),
    };

    (SupabaseWrapper.get as jest.Mock).mockReturnValue(mockSupabaseChain);
  });

  describe('listEscolas', () => {
    it('should return 200 and a list of escolas on success', async () => {
      const escolasData = [
        { id: 1, nome: 'Escola A' },
        { id: 2, nome: 'Escola B' },
      ];
      mockSupabaseChain.select.mockResolvedValueOnce({
        data: escolasData,
        error: null,
      });

      await EscolasController.routes.list!.value(mockRequest as Request, mockResponse as Response);

      expect(mockResponse.status).toHaveBeenCalledWith(200);
      expect(mockResponse.json).toHaveBeenCalledWith(escolasData);
    });

    it('should return 500 if there is a Supabase error', async () => {
      mockSupabaseChain.select.mockResolvedValueOnce({
        data: null,
        error: { message: 'Database error' },
      });

      await EscolasController.routes.list!.value(mockRequest as Request, mockResponse as Response);

      expect(mockResponse.status).toHaveBeenCalledWith(500);
      expect(mockResponse.json).toHaveBeenCalledWith({ error: 'Error listing escolas' });
    });
  });
});
