<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;

use App\Models\Fee;
use App\Models\Payment;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

class PaymentController extends Controller
{
    // Paystack Secret Key (Should be in .env but using placeholder/config for now)
    // private $secretKey = env('PAYSTACK_SECRET_KEY');

    /**
     * Get payment history
     */
    public function index(Request $request)
    {
        $query = Payment::with(['fee', 'student'])
            ->orderBy('created_at', 'desc');

        if ($request->has('student_id')) {
            $query->where('student_id', $request->student_id);
        }

        $payments = $query->paginate(20);

        return response()->json($payments);
    }

    /**
     * Initialize a payment (Optional: if generating access code from backend)
     */
    public function initialize(Request $request)
    {
        $validated = $request->validate([
            'email' => 'required|email',
            'amount' => 'required|numeric', // Amount in Naira
            'student_id' => 'required|exists:students,id',
            'fee_id' => 'required|exists:fees,id',
        ]);

        // Convert to kobo
        $amountKobo = $validated['amount'] * 100;

        // Generate a unique internal reference
        $reference = 'PAY_'.time().'_'.uniqid();

        try {
            // Find student and school for subaccount split
            $student = \App\Models\Student::with('school')->find($validated['student_id']);
            $subaccount = $student->school->paystack_subaccount_code ?? null;

            // Using Http Client to call Paystack
            $response = Http::withHeaders([
                'Authorization' => 'Bearer '.env('PAYSTACK_SECRET_KEY'),
                'Content-Type' => 'application/json',
            ])->post('https://api.paystack.co/transaction/initialize', [
                'email' => $validated['email'],
                'amount' => $amountKobo,
                'reference' => $reference,
                'subaccount' => $subaccount, // Paystack will ignore if null
                'callback_url' => env('APP_URL').'/api/payments/callback', // Or handle on mobile
                'metadata' => [
                    'student_id' => $validated['student_id'],
                    'fee_id' => $validated['fee_id'],
                ],
            ]);

            if ($response->successful()) {
                $data = $response->json();

                // Record pending payment
                Payment::create([
                    'student_id' => $validated['student_id'],
                    'fee_id' => $validated['fee_id'],
                    'amount' => $validated['amount'],
                    'payment_method' => 'paystack',
                    'reference' => $reference,
                    'status' => 'pending',
                ]);

                return response()->json($data['data']);
            } else {
                return response()->json(['message' => 'Payment initialization failed', 'error' => $response->body()], 400);
            }
        } catch (\Exception $e) {
            Log::error('Paystack Error: '.$e->getMessage());

            return response()->json(['message' => 'Payment service error'], 500);
        }
    }

    /**
     * Verify payment after frontend success
     */
    public function verify(Request $request)
    {
        $validated = $request->validate([
            'reference' => 'required|string',
            // If the frontend already collected metadata, good, otherwise we rely on stored pending payment
            // 'student_id' => 'exists:students,id', // Optional if we strictly rely on reference lookup
            // 'fee_id' => 'exists:fees,id',
        ]);

        $reference = $validated['reference'];

        // Find the local record if it exists (from initialize) OR create if pure client-side flow
        // For robustness, we check Paystack first

        try {
            $response = Http::withHeaders([
                'Authorization' => 'Bearer '.env('PAYSTACK_SECRET_KEY'),
            ])->get("https://api.paystack.co/transaction/verify/{$reference}");

            if ($response->successful()) {
                $data = $response->json();

                if ($data['status'] === true && $data['data']['status'] === 'success') {
                    $paystackData = $data['data'];

                    // Transaction successful
                    // Check if we have a local record
                    $payment = Payment::where('reference', $reference)->first();

                    if ($payment) {
                        // Update existing
                        if ($payment->status !== 'success') {
                            $payment->update([
                                'status' => 'success',
                                'gateway_response' => $paystackData,
                                'paid_at' => now(),
                            ]);
                        }
                    } else {
                        // Create new (Client-side init flow)
                        // Need student_id and fee_id likely passed from frontend or metadata

                        $meta = $paystackData['metadata'] ?? [];

                        // Fallback: require student_id/fee_id in request if not in metadata
                        $studentId = $meta['student_id'] ?? $request->student_id;
                        $feeId = $meta['fee_id'] ?? $request->fee_id;

                        if (! $studentId || ! $feeId) {
                            return response()->json(['message' => 'Missing payment metadata'], 400);
                        }

                        $payment = Payment::create([
                            'student_id' => $studentId,
                            'fee_id' => $feeId,
                            'amount' => $paystackData['amount'] / 100, // Convert back to main unit
                            'payment_method' => $paystackData['channel'],
                            'reference' => $reference,
                            'status' => 'success',
                            'gateway_response' => $paystackData,
                            'paid_at' => now(),
                        ]);
                    }

                    // Transaction verified and recorded
                    // Fee balance logic is handled by calculating existing transactions
                    
                    return response()->json([
                        'message' => 'Payment verified successfully',
                        'data' => $payment,
                    ]);
                } else {
                    return response()->json(['message' => 'Payment verification failed: '.$data['data']['gateway_response']], 400);
                }
            } else {
                return response()->json(['message' => 'Unable to verify payment'], 400);
            }
        } catch (\Exception $e) {
            Log::error('Payment Verification Error: '.$e->getMessage());

            return response()->json(['message' => 'Verification service error'], 500);
        }
    }
}
