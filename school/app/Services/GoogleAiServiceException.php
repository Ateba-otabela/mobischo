<?php

namespace App\Services;

use RuntimeException;

class GoogleAiServiceException extends RuntimeException
{
    private $category;
    private $providerStatus;

    public function __construct(string $category, ?int $providerStatus = null)
    {
        parent::__construct('Google AI request failed.');
        $this->category = $category;
        $this->providerStatus = $providerStatus;
    }

    public function category(): string
    {
        return $this->category;
    }

    public function providerStatus(): ?int
    {
        return $this->providerStatus;
    }
}
