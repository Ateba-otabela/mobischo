<?php

namespace Tests\Feature;

use App\Models\User;
use App\Notifications\MobischoDatabaseNotification;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class NotificationInboxControllerTest extends TestCase
{
    use RefreshDatabase;

    private function createUser(string $code, string $accountType): User
    {
        return User::create([
            'code' => $code,
            'nom' => ucfirst($accountType),
            'prenom' => 'Test',
            'sex' => 'F',
            'login' => $code,
            'contacts' => '000000000',
            'password' => bcrypt('test-password'),
            'account_type' => $accountType,
            'CodeEtablissement' => 'SCHOOL-1',
        ]);
    }

    public function test_notification_list_returns_unread_count_and_hides_class_from_parent(): void
    {
        $parent = $this->createUser('P-1', 'parent');
        $parent->notify(new MobischoDatabaseNotification(
            'Absence scolaire',
            'Élève absent.',
            [
                'type' => 'attendance',
                'class_code' => 'C-1',
                'class_name' => '6e A',
                'recipient_role' => 'parent',
            ]
        ));
        $parent->notify(new MobischoDatabaseNotification(
            'Retard scolaire',
            'Élève en retard.',
            ['type' => 'attendance', 'recipient_role' => 'parent']
        ));

        Sanctum::actingAs($parent);

        $response = $this->getJson('/api/notifications')
            ->assertOk()
            ->assertJsonCount(2, 'data')
            ->assertJsonPath('unread_count', 2)
            ->assertJsonPath('data.0.is_read', false);

        foreach ($response->json('data') as $notification) {
            $this->assertArrayNotHasKey('class_code', $notification['data']);
            $this->assertArrayNotHasKey('class_name', $notification['data']);
        }
    }

    public function test_notification_list_includes_scoped_class_for_staff_and_read_actions_update_badge(): void
    {
        $encadreur = $this->createUser('ENC-1', 'encadreur');
        $encadreur->notify(new MobischoDatabaseNotification(
            'Absence scolaire',
            'Élève absent. Classe : 6e A.',
            [
                'type' => 'attendance',
                'class_code' => 'C-1',
                'class_name' => '6e A',
                'recipient_role' => 'encadreur',
            ]
        ));
        $encadreur->notify(new MobischoDatabaseNotification(
            'Retard scolaire',
            'Élève en retard. Classe : 6e A.',
            [
                'type' => 'attendance',
                'class_code' => 'C-1',
                'class_name' => '6e A',
                'recipient_role' => 'encadreur',
            ]
        ));

        Sanctum::actingAs($encadreur);
        $listing = $this->getJson('/api/notifications')
            ->assertOk()
            ->assertJsonCount(2, 'data')
            ->assertJsonPath('unread_count', 2)
            ->assertJsonPath('data.0.data.class_name', '6e A');

        $notificationId = $listing->json('data.0.id');
        $this->patchJson('/api/notifications/'.$notificationId.'/read')
            ->assertOk()
            ->assertJsonPath('unread_count', 1);

        $this->postJson('/api/notifications/read-all')
            ->assertOk()
            ->assertJsonPath('unread_count', 0);

        $this->getJson('/api/notifications')
            ->assertOk()
            ->assertJsonPath('unread_count', 0)
            ->assertJsonPath('data.0.is_read', true)
            ->assertJsonPath('data.1.is_read', true);
    }

    public function test_notification_read_route_cannot_read_another_users_notification(): void
    {
        $firstUser = $this->createUser('P-1', 'parent');
        $otherUser = $this->createUser('P-2', 'parent');
        $otherUser->notify(new MobischoDatabaseNotification(
            'Absence scolaire',
            'Élève absent.',
            ['type' => 'attendance']
        ));

        Sanctum::actingAs($firstUser);
        $notificationId = $otherUser->notifications()->firstOrFail()->id;

        $this->patchJson('/api/notifications/'.$notificationId.'/read')
            ->assertNotFound();
    }

    public function test_notification_routes_require_authentication(): void
    {
        $this->getJson('/api/notifications')->assertUnauthorized();
        $this->postJson('/api/notifications/read-all')->assertUnauthorized();
    }
}
