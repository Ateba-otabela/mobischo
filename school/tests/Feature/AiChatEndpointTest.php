<?php

namespace Tests\Feature;

use App\Models\User;
use App\Models\AiConversation;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Schema;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class AiChatEndpointTest extends TestCase
{
    protected function setUp(): void
    {
        parent::setUp();

        config([
            'database.default' => 'sqlite',
            'database.connections.sqlite' => [
                'driver' => 'sqlite',
                'database' => ':memory:',
                'prefix' => '',
                'foreign_key_constraints' => true,
            ],
        ]);
        DB::purge('sqlite');

        Schema::create('users', function (Blueprint $table) {
            $table->string('code')->primary();
        });
        Schema::create('ai_conversations', function (Blueprint $table) {
            $table->id();
            $table->string('user_code');
            $table->string('title')->nullable();
            $table->timestamps();
            $table->foreign('user_code')->references('code')->on('users')->cascadeOnDelete();
            $table->index(['user_code', 'updated_at']);
        });
        Schema::create('ai_messages', function (Blueprint $table) {
            $table->id();
            $table->foreignId('conversation_id')->constrained('ai_conversations')->cascadeOnDelete();
            $table->enum('role', ['user', 'assistant']);
            $table->text('content');
            $table->timestamps();
            $table->index(['conversation_id', 'created_at']);
        });
    }

    private function principal(string $code): User
    {
        DB::table('users')->insert(['code' => $code]);

        return (new User())->forceFill([
            'code' => $code,
            'account_type' => 'principal_encadreur',
            'admin' => '0',
            'CodeEtablissement' => 'school-a',
        ]);
    }

    public function test_chat_endpoint_requires_sanctum_authentication(): void
    {
        $this->postJson('/api/ai/chat', ['message' => 'Bonjour'])
            ->assertUnauthorized();
    }

    public function test_conversation_endpoints_require_sanctum_authentication(): void
    {
        $this->getJson('/api/ai/conversations')->assertUnauthorized();
        $this->postJson('/api/ai/conversations')->assertUnauthorized();
        $this->getJson('/api/ai/conversations/1')->assertUnauthorized();
        $this->postJson('/api/ai/conversations/1/messages', ['message' => 'Bonjour'])
            ->assertUnauthorized();
        $this->deleteJson('/api/ai/conversations/1')->assertUnauthorized();
    }

    public function test_non_principal_users_cannot_use_the_ai_gateway(): void
    {
        $user = $this->principal('test-parent')->forceFill([
            'account_type' => 'parent',
        ]);
        Sanctum::actingAs($user, ['ai:chat']);
        Http::fake();

        $this->postJson('/api/ai/chat', ['message' => 'Bonjour'])
            ->assertForbidden()
            ->assertJson(['success' => false]);
        Http::assertNothingSent();
    }

    public function test_principal_chat_returns_ai_text_and_forwards_conversation(): void
    {
        config([
            'services.google_ai.api_key' => 'test-only-key',
            'services.google_ai.model' => 'test-model',
        ]);
        $user = $this->principal('test-principal');
        Sanctum::actingAs($user, ['ai:chat']);
        Http::fake([
            'generativelanguage.googleapis.com/*' => Http::response([
                'candidates' => [[
                    'content' => ['parts' => [['text' => 'Bonjour 👋']]],
                ]],
            ], 200),
        ]);

        $this->postJson('/api/ai/chat', [
            'message' => 'Bonjour',
            'conversation' => [
                ['role' => 'user', 'text' => 'Salut'],
                ['role' => 'assistant', 'text' => 'Bonjour.'],
            ],
        ])->assertOk()->assertJson([
            'success' => true,
            'message' => 'Bonjour 👋',
        ])->assertJsonStructure(['success', 'message', 'conversation_id'])
            ->assertDontSee('test-only-key');

        Http::assertSent(function (\Illuminate\Http\Client\Request $request) {
            return $request['contents'][0]['role'] === 'user'
                && $request['contents'][1]['role'] === 'model'
                && $request['contents'][2]['parts'][0]['text'] === 'Bonjour';
        });
    }

    public function test_provider_errors_are_returned_without_upstream_details(): void
    {
        config([
            'services.google_ai.api_key' => 'test-only-key',
            'services.google_ai.model' => 'test-model',
        ]);
        $user = $this->principal('test-principal');
        Sanctum::actingAs($user, ['ai:chat']);
        Http::fake([
            'generativelanguage.googleapis.com/*' => Http::response([
                'error' => ['message' => 'upstream-secret-detail'],
            ], 429),
        ]);

        $this->postJson('/api/ai/chat', ['message' => 'Bonjour'])
            ->assertStatus(502)
            ->assertJson([
                'success' => false,
                'message' => 'Désolé, je rencontre actuellement un problème de connexion. Veuillez réessayer.',
            ])
            ->assertDontSee('upstream-secret-detail')
            ->assertDontSee('test-only-key');
    }

    public function test_conversation_creation_and_history_are_persistent_and_account_scoped(): void
    {
        $principalA = $this->principal('principal-a');
        Sanctum::actingAs($principalA, ['ai:chat']);

        $created = $this->postJson('/api/ai/conversations')
            ->assertCreated()
            ->assertJson(['title' => 'Nouvelle conversation']);
        $conversationId = $created->json('id');

        config([
            'services.google_ai.api_key' => 'test-only-key',
            'services.google_ai.model' => 'test-model',
        ]);
        Http::fake([
            'generativelanguage.googleapis.com/*' => Http::response([
                'candidates' => [[
                    'content' => ['parts' => [['text' => 'Réponse persistée']]],
                ]],
            ], 200),
        ]);

        $this->postJson('/api/ai/chat', [
            'conversation_id' => $conversationId,
            'message' => 'Présence de la semaine',
        ])->assertOk()->assertJson([
            'success' => true,
            'conversation_id' => $conversationId,
        ]);

        $this->getJson('/api/ai/conversations')
            ->assertOk()
            ->assertJsonPath('data.0.id', $conversationId)
            ->assertJsonPath('data.0.title', 'Présence de la semaine');

        $this->getJson('/api/ai/conversations/'.$conversationId)
            ->assertOk()
            ->assertJsonPath('messages.0.role', 'user')
            ->assertJsonPath('messages.0.content', 'Présence de la semaine')
            ->assertJsonPath('messages.1.role', 'assistant')
            ->assertJsonPath('messages.1.content', 'Réponse persistée');

        $principalB = $this->principal('principal-b');
        Sanctum::actingAs($principalB, ['ai:chat']);
        $this->getJson('/api/ai/conversations')->assertJsonPath('data', []);
        $this->getJson('/api/ai/conversations/'.$conversationId)->assertNotFound();
        $this->postJson('/api/ai/conversations/'.$conversationId.'/messages', [
            'message' => 'Accès croisé',
        ])->assertNotFound();
        $this->deleteJson('/api/ai/conversations/'.$conversationId)->assertNotFound();
        $this->postJson('/api/ai/chat', [
            'conversation_id' => $conversationId,
            'message' => 'Accès croisé',
        ])->assertNotFound();

        $this->assertDatabaseHas('ai_conversations', [
            'id' => $conversationId,
            'user_code' => 'principal-a',
        ]);
    }

    public function test_owner_can_delete_conversation_and_messages_cascade(): void
    {
        $user = $this->principal('principal-delete');
        Sanctum::actingAs($user, ['ai:chat']);
        $conversation = AiConversation::create([
            'user_code' => $user->code,
            'title' => 'À supprimer',
        ]);
        $conversation->messages()->create([
            'role' => 'user',
            'content' => 'Message',
        ]);

        $this->deleteJson('/api/ai/conversations/'.$conversation->id)
            ->assertOk()
            ->assertJson(['success' => true]);

        $this->assertDatabaseMissing('ai_conversations', ['id' => $conversation->id]);
        $this->assertDatabaseMissing('ai_messages', ['conversation_id' => $conversation->id]);
    }
}