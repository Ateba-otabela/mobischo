<?php

namespace Tests\Feature;

use Tests\TestCase;

class InstitutionDiscoveryTest extends TestCase
{
    public function test_get_institutions_returns_catalog_payload(): void
    {
        $response = $this->postJson('/api/school_manager', [
            'action' => 'GET_INSTITUTIONS',
            'page' => 1,
            'per_page' => 2,
        ]);

        $response->assertOk();
        $response->assertJsonStructure([
            'data' => [
                '*' => [
                    'id',
                    'name',
                    'type',
                    'category',
                    'location',
                    'city',
                    'region',
                    'description',
                    'programs',
                    'languages',
                    'logo_url',
                    'image_url',
                    'website_url',
                    'featured',
                ],
            ],
            'total',
            'page',
            'per_page',
            'total_pages',
        ]);

        $this->assertIsArray($response->json('data'));
        $this->assertNotEmpty($response->json('data'));
        $this->assertSame(1, $response->json('page'));
        $this->assertSame(2, $response->json('per_page'));
        $this->assertGreaterThan(0, $response->json('total'));
        $this->assertSame('Université de Douala', $response->json('data.0.name'));
    }

    public function test_get_institutions_filters_and_empty_results_use_http_200(): void
    {
        $searchResponse = $this->postJson('/api/school_manager', [
            'action' => 'GET_INSTITUTIONS',
            'search' => 'Douala',
            'type' => 'public',
            'category' => 'universitaire',
            'location' => 'Littoral',
        ]);

        $searchResponse->assertOk();
        $this->assertNotEmpty($searchResponse->json('data'));
        $this->assertSame('Université de Douala', $searchResponse->json('data.0.name'));

        $privateResponse = $this->postJson('/api/school_manager', [
            'action' => 'GET_INSTITUTIONS',
            'type' => 'private',
        ]);

        $privateResponse->assertOk();
        $this->assertNotEmpty($privateResponse->json('data'));
        $this->assertContains('privé', array_map(static fn ($item) => strtolower((string) ($item['type'] ?? '')), $privateResponse->json('data')));

        $emptyResponse = $this->postJson('/api/school_manager', [
            'action' => 'GET_INSTITUTIONS',
            'search' => 'definitely-not-a-real-institution-name-xyz',
        ]);

        $emptyResponse->assertOk();
        $this->assertSame(0, $emptyResponse->json('total'));
        $this->assertSame([], $emptyResponse->json('data'));
    }
}
