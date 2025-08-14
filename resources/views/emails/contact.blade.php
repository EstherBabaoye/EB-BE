@component('mail::message')
# New Contact Message

You just received a new message from your website.

@component('mail::panel')
**From:** {{ $data['name'] }}  
**Email:** {{ $data['email'] }}  
**Subject:** {{ $data['subject'] ?? '—' }}
@endcomponent

**Message:**

{{ $data['message'] }}

@slot('subcopy')
If you want to reply, just hit **Reply** in your email client — it will go to **{{ $data['email'] }}**.
@endslot

Thanks,  
**EB Website**
@endcomponent
