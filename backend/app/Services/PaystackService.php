<?php

namespace App\Services;

use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

class PaystackService
{
    protected $baseUrl = 'https://api.paystack.co';
    protected $secretKey;

    public function __construct()
    {
        $this->secretKey = env('PAYSTACK_SECRET_KEY');
    }

    /**
     * Fetch list of supported banks in Nigeria
     */
    public function fetchBanks()
    {
        try {
            $response = Http::withHeaders([
                'Authorization' => 'Bearer ' . $this->secretKey,
            ])->get($this->baseUrl . '/bank', [
                'currency' => 'NGN',
                'country' => 'nigeria'
            ]);

            if ($response->successful()) {
                return $response->json()['data'];
            }

            Log::error('Paystack Banks Fetch Error: ' . $response->body());
            return [];
        } catch (\Exception $e) {
            Log::error('Paystack Banks Fetch Exception: ' . $e->getMessage());
            return [];
        }
    }

    /**
     * Create a subaccount on Paystack
     */
    public function createSubaccount(array $data)
    {
        try {
            $response = Http::withHeaders([
                'Authorization' => 'Bearer ' . $this->secretKey,
                'Content-Type' => 'application/json',
            ])->post($this->baseUrl . '/subaccount', [
                'business_name' => $data['business_name'],
                'settlement_bank' => $data['settlement_bank'],
                'account_number' => $data['account_number'],
                'percentage_charge' => $data['percentage_charge'] ?? 2, // Default 2%
            ]);

            if ($response->successful()) {
                return $response->json()['data'];
            }

            Log::error('Paystack Subaccount Creation Error: ' . $response->body());
            return [
                'success' => false,
                'message' => $response->json()['message'] ?? 'Failed to create subaccount'
            ];
        } catch (\Exception $e) {
            Log::error('Paystack Subaccount Creation Exception: ' . $e->getMessage());
            return [
                'success' => false,
                'message' => 'Service error during subaccount creation'
            ];
        }
    }
}
