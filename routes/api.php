<?php
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\MailController;

Route::post('/send-mail', [MailController::class, 'sendMail']);
