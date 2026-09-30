<?php

namespace App\Http\Controllers;

use App\Models\AiConversation;
use App\Models\AiMessage;
use App\Models\User;
use App\Services\AiReadOnlyToolService;
use App\Services\GoogleAiService;
use App\Services\GoogleAiServiceException;
use App\Services\MobischoNavigationKnowledgeService;
use App\Services\PrincipalContextService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Str;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Facades\Log;
use Throwable;

class AiChatController extends Controller
{
    private $principalContext;
    private $navigationKnowledge;

    public function __construct(
        PrincipalContextService $principalContext,
        MobischoNavigationKnowledgeService $navigationKnowledge
    )
    {
        $this->principalContext = $principalContext;
        $this->navigationKnowledge = $navigationKnowledge;
    }

    public function chat(
        Request $request,
        GoogleAiService $googleAi,
        AiReadOnlyToolService $aiTools
    ): JsonResponse
    {
        $user = $request->user();
        if (!$user instanceof User || !$this->canAccessAi($user)) {
            return response()->json([
                'success' => false,
                'message' => 'Accès non autorisé.',
            ], 403);
        }

        $validator = Validator::make($request->all(), [
            'message' => 'required|string|max:4000',
            'conversation_id' => 'sometimes|nullable|integer|min:1',
            'conversation' => 'sometimes|array|max:20',
            'conversation.*.role' => 'required|in:user,assistant',
            'conversation.*.text' => 'required|string|max:4000',
        ]);
        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Le message est invalide. Veuillez réessayer.',
            ], 422);
        }

        try {
            $conversation = $this->resolveConversationForUser($user, $request);
            if ($conversation === null && $request->filled('conversation_id')) {
                return response()->json([
                    'success' => false,
                    'message' => 'Conversation introuvable.',
                ], 404);
            }

            $conversationContext = $this->buildContextForProvider(
                $request->filled('conversation_id') ? $conversation : null,
                $request->input('conversation', [])
            );

            $message = (string) $request->input('message');
            $this->storeUserMessage($conversation, $message);

            $reply = $this->navigationKnowledge->answerNavigationQuestion($user, $message);
            if ($reply === null) {
                $reply = $googleAi->generateReply(
                    $message,
                    $conversationContext,
                    function ($toolName, array $arguments) use ($user, $aiTools) {
                        return $aiTools->execute($user, (string) $toolName, $arguments);
                    },
                    $aiTools->functionDeclarations($user),
                    $this->navigationKnowledge->forUser($user)
                );
            }

            $this->storeAssistantMessage($conversation, $reply);

            if ($conversation && $conversation->wasRecentlyCreated) {
                $conversation->refresh();
            }

            return response()->json([
                'success' => true,
                'message' => $reply,
                'conversation_id' => $conversation ? $conversation->id : null,
            ]);
        } catch (GoogleAiServiceException $exception) {
            Log::warning('Mobischo AI provider request failed', [
                'category' => $exception->category(),
                'provider_status' => $exception->providerStatus(),
                'api_key_configured' => trim((string) config('services.google_ai.api_key', '')) !== '',
                'model_configured' => trim((string) config('services.google_ai.model', '')) !== '',
                'model' => (string) config('services.google_ai.model', ''),
            ]);

            return response()->json([
                'success' => false,
                'message' => 'Désolé, je rencontre actuellement un problème de connexion. Veuillez réessayer.',
            ], 502);
        } catch (Throwable $exception) {
            Log::error('Mobischo AI internal failure', [
                'exception_type' => get_class($exception),
            ]);

            return response()->json([
                'success' => false,
                'message' => 'Désolé, je rencontre actuellement un problème de connexion. Veuillez réessayer.',
            ], 502);
        }
    }

    public function index(Request $request): JsonResponse
    {
        $user = $request->user();
        if (!$user instanceof User || !$this->canAccessAi($user)) {
            return response()->json(['message' => 'Accès non autorisé.'], 403);
        }

        $page = max(1, min(1000000, (int) $request->query('page', 1)));
        $conversationPage = AiConversation::query()
            ->withCount('messages')
            ->where('user_code', $user->code)
            ->orderByDesc('updated_at')
            ->limit(51)
            ->offset(($page - 1) * 50)
            ->get();
        $hasMore = $conversationPage->count() > 50;
        $conversations = $conversationPage->take(50)
            ->map(function (AiConversation $conversation) {
                return [
                    'id' => $conversation->id,
                    'title' => $conversation->title ?: 'Nouvelle conversation',
                    'updated_at' => $conversation->updated_at ? $conversation->updated_at->toIso8601String() : null,
                    'message_count' => (int) $conversation->messages_count,
                ];
            });

        return response()->json([
            'data' => $conversations,
            'page' => $page,
            'has_more' => $hasMore,
        ]);
    }

    public function show(Request $request, int $conversationId): JsonResponse
    {
        $user = $request->user();
        if (!$user instanceof User || !$this->canAccessAi($user)) {
            return response()->json(['message' => 'Accès non autorisé.'], 403);
        }

        $conversation = AiConversation::where('id', $conversationId)
            ->where('user_code', $user->code)
            ->first();
        if (!$conversation instanceof AiConversation) {
            return response()->json(['message' => 'Conversation introuvable.'], 404);
        }

        $conversation->load(['messages' => function ($query) {
            $query->orderByDesc('id')->limit(80);
        }]);

        return response()->json([
            'id' => $conversation->id,
            'title' => $conversation->title ?: 'Nouvelle conversation',
            'updated_at' => optional($conversation->updated_at)->toIso8601String(),
            'messages' => $conversation->messages->reverse()->values()->map(function (AiMessage $message) {
                return [
                    'id' => $message->id,
                    'role' => $message->role,
                    'content' => $message->content,
                    'created_at' => optional($message->created_at)->toIso8601String(),
                ];
            })->values(),
        ]);
    }

    public function store(Request $request): JsonResponse
    {
        $user = $request->user();
        if (!$user instanceof User || !$this->canAccessAi($user)) {
            return response()->json(['message' => 'Accès non autorisé.'], 403);
        }

        $validator = Validator::make($request->all(), [
            'title' => 'sometimes|string|max:120',
        ]);
        if ($validator->fails()) {
            return response()->json(['message' => 'La conversation est invalide.'], 422);
        }

        $conversation = AiConversation::create([
            'user_code' => $user->code,
            'title' => trim((string) $request->input('title', '')) !== ''
                ? trim((string) $request->input('title'))
                : 'Nouvelle conversation',
        ]);

        return response()->json([
            'id' => $conversation->id,
            'title' => $conversation->title,
            'updated_at' => optional($conversation->updated_at)->toIso8601String(),
            'messages' => [],
        ], 201);
    }

    public function sendMessage(Request $request, int $conversationId): JsonResponse
    {
        $user = $request->user();
        if (!$user instanceof User || !$this->canAccessAi($user)) {
            return response()->json(['message' => 'Accès non autorisé.'], 403);
        }

        $conversation = AiConversation::where('id', $conversationId)
            ->where('user_code', $user->code)
            ->first();
        if (!$conversation instanceof AiConversation) {
            return response()->json(['message' => 'Conversation introuvable.'], 404);
        }

        $request->merge(['conversation_id' => $conversation->id]);

        return $this->chat(
            $request,
            app(GoogleAiService::class),
            app(AiReadOnlyToolService::class)
        );
    }

    public function destroy(Request $request, int $conversationId): JsonResponse
    {
        $user = $request->user();
        if (!$user instanceof User || !$this->canAccessAi($user)) {
            return response()->json(['message' => 'Accès non autorisé.'], 403);
        }

        $conversation = AiConversation::where('id', $conversationId)
            ->where('user_code', $user->code)
            ->first();
        if (!$conversation instanceof AiConversation) {
            return response()->json(['message' => 'Conversation introuvable.'], 404);
        }

        $conversation->delete();

        return response()->json(['success' => true]);
    }

    private function resolveConversationForUser(User $user, Request $request): ?AiConversation
    {
        $conversationId = $request->input('conversation_id');
        if ($conversationId !== null && $conversationId !== '') {
            $conversation = AiConversation::where('id', (int) $conversationId)
                ->where('user_code', $user->code)
                ->first();

            if ($conversation instanceof AiConversation) {
                return $conversation;
            }

            return null;
        }

        $message = trim((string) $request->input('message', ''));
        if ($message === '') {
            return null;
        }

        return AiConversation::create([
            'user_code' => $user->code,
            'title' => $this->generateConversationTitle($message),
        ]);
    }

    private function buildContextForProvider(?AiConversation $conversation, array $requestContext): array
    {
        $context = [];

        if ($conversation instanceof AiConversation) {
            $conversationMessages = $conversation->messages()
                ->orderByDesc('id')
                ->limit(20)
                ->get();

            foreach ($conversationMessages->reverse() as $message) {
                $context[] = [
                    'role' => $message->role,
                    'text' => $message->content,
                ];
            }
        } else {
            foreach ($requestContext as $turn) {
                if (!is_array($turn) || !isset($turn['role'], $turn['text'])) {
                    continue;
                }

                $context[] = [
                    'role' => in_array((string) $turn['role'], ['user', 'assistant'], true)
                        ? (string) $turn['role']
                        : 'user',
                    'text' => (string) $turn['text'],
                ];
            }
        }

        $normalized = [];
        foreach ($context as $turn) {
            $text = trim((string) ($turn['text'] ?? ''));
            if ($text === '') {
                continue;
            }

            $normalized[] = [
                'role' => in_array((string) ($turn['role'] ?? 'user'), ['user', 'assistant'], true)
                    ? (string) $turn['role']
                    : 'user',
                'text' => $text,
            ];
        }

        return array_map(function (array $turn) {
            return [
                'role' => $turn['role'],
                'text' => mb_substr($turn['text'], 0, 2000),
            ];
        }, array_slice($normalized, -19));
    }

    private function storeUserMessage(?AiConversation $conversation, string $message): void
    {
        if (!$conversation instanceof AiConversation) {
            return;
        }

        if ($conversation->title === null || trim((string) $conversation->title) === '' ||
            trim((string) $conversation->title) === 'Nouvelle conversation') {
            $conversation->update([
                'title' => $this->generateConversationTitle($message),
            ]);
        }

        AiMessage::create([
            'conversation_id' => $conversation->id,
            'role' => 'user',
            'content' => $message,
        ]);

        $conversation->touch();
    }

    private function storeAssistantMessage(?AiConversation $conversation, string $reply): void
    {
        if (!$conversation instanceof AiConversation) {
            return;
        }

        AiMessage::create([
            'conversation_id' => $conversation->id,
            'role' => 'assistant',
            'content' => $reply,
        ]);

        $conversation->touch();
    }

    private function generateConversationTitle(string $message): string
    {
        $text = preg_replace('/\s+/', ' ', trim(strip_tags($message)));
        $text = trim((string) ($text ?? ''));

        if ($text === '') {
            return 'Nouvelle conversation';
        }

        return Str::limit($text, 42, '…');
    }

    private function canAccessAi(User $user): bool
    {
        return $this->principalContext->resolveForAi($user) !== null;
    }
}