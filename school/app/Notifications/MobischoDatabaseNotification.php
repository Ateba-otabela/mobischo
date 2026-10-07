<?php

namespace App\Notifications;

use Illuminate\Notifications\Notification;

class MobischoDatabaseNotification extends Notification
{
    private string $title;
    private string $body;
    private array $data;

    public function __construct(string $title, string $body, array $data)
    {
        $this->title = $title;
        $this->body = $body;
        $this->data = $data;
    }

    public function via($notifiable): array
    {
        return ['database'];
    }

    public function toDatabase($notifiable): array
    {
        return [
            'title' => $this->title,
            'body' => $this->body,
            'data' => $this->data,
        ];
    }
}
