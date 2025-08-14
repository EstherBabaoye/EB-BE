<?php

namespace App\Mail;

use Illuminate\Bus\Queueable;
use Illuminate\Mail\Mailable;
use Illuminate\Queue\SerializesModels;

class ContactFormMail extends Mailable
{
    use Queueable, SerializesModels;

    public array $data;

    public function __construct(array $data)
    {
        // expected keys: name, email, subject (optional), message
        $this->data = $data;
    }

    public function build()
    {
        // EXTRA TIP IMPLEMENTED:
        // Use your Gmail as the actual from-address, but display the sender's name.
        // Reply-To is the sender's email so you can reply directly.
        return $this->from(env('MAIL_FROM_ADDRESS'), $this->data['name'])
            ->replyTo($this->data['email'], $this->data['name'])
            ->subject($this->data['subject'] ?? 'New Contact Message')
            ->markdown('emails.contact', ['data' => $this->data]);
    }
}
