<?php

return [
    // Only /api routes need it; this is the Laravel default and is reliable
    'paths' => ['api/*', 'sanctum/csrf-cookie'],

    'allowed_methods' => ['*'],

    'allowed_origins' => [
        'https://esther-babaoye.netlify.app',
        'http://localhost:5173',
        'http://127.0.0.1:5173',
    ],

    'allowed_origins_patterns' => [],

    'allowed_headers' => ['*'],
    'exposed_headers' => [],
    'max_age' => 0,

    // Keep false unless you actually need cookies
    'supports_credentials' => false,
];
