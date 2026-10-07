<?php

namespace App\Http\Controllers;

use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class MobileNotificationController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $user = $request->user();
        if (!$user instanceof User) {
            return response()->json(['message' => 'Unauthenticated.'], 401);
        }

        $items = $user->notifications()
            ->latest()
            ->limit(50)
            ->get()
            ->map(function ($notification) use ($user) {
                $stored = $notification->data;
                $data = is_array($stored['data'] ?? null) ? $stored['data'] : [];

                if (strtolower((string) $user->account_type) === 'parent') {
                    unset($data['class_code'], $data['class_name'], $data['class_label']);
                }

                return [
                    'id' => (string) $notification->id,
                    'title' => (string) ($stored['title'] ?? ''),
                    'body' => (string) ($stored['body'] ?? ''),
                    'data' => $data,
                    'created_at' => $notification->created_at,
                    'read_at' => $notification->read_at,
                    'is_read' => $notification->read_at !== null,
                ];
            })
            ->values();

        return response()->json([
            'data' => $items,
            'unread_count' => $user->unreadNotifications()->count(),
        ]);
    }

    public function markAsRead(Request $request, string $notificationId): JsonResponse
    {
        $user = $request->user();
        if (!$user instanceof User) {
            return response()->json(['message' => 'Unauthenticated.'], 401);
        }

        $notification = $user->notifications()
            ->where('id', $notificationId)
            ->firstOrFail();
        $notification->markAsRead();

        return response()->json([
            'success' => true,
            'unread_count' => $user->unreadNotifications()->count(),
        ]);
    }

    public function markAllAsRead(Request $request): JsonResponse
    {
        $user = $request->user();
        if (!$user instanceof User) {
            return response()->json(['message' => 'Unauthenticated.'], 401);
        }

        $user->unreadNotifications()->update(['read_at' => now()]);

        return response()->json([
            'success' => true,
            'unread_count' => 0,
        ]);
    }
}
