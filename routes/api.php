<?php

use Illuminate\Http\Response;
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\MailController;

// Handle all CORS preflight requests cleanly
Route::options('/{any}', function () {
    return response('', Response::HTTP_NO_CONTENT);
})->where('any', '.*');

// Actual POST request
Route::post('/send-mail', [MailController::class, 'sendMail']);
