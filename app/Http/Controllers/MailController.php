<?php

// app/Http/Controllers/MailController.php
namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Mail;

class MailController extends Controller
{
    public function sendMail(Request $request)
    {
        $validated = $request->validate([
            'name' => 'required|string|max:120',
            'email' => 'required|email',
            'message' => 'required|string|max:5000',
        ]);

        try {
            Mail::raw(
                "Name: {$validated['name']}\nEmail: {$validated['email']}\n\nMessage:\n{$validated['message']}",
                function ($m) use ($validated) {
                    $m->to('estherbabaoye@gmail.com')   // where you want to receive it
                      ->subject('New Contact Message');
                }
            );

            return response()->json(['ok' => true, 'message' => 'Sent'], 200);
        } catch (\Throwable $e) {
            // log for debugging
            Log::error('Mail send failed', ['error' => $e->getMessage()]);
            return response()->json(['ok' => false, 'error' => 'Mail failed'], 500);
        }
    }
}
