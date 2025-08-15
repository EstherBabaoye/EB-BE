<?php
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\MailController;

// Handle preflight OPTIONS request
Route::options('/send-mail', function () {
    return response()->noContent();
});

// Actual POST request
Route::post('/send-mail', [MailController::class, 'sendMail']);
