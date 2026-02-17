<?php

namespace Tests\Feature;

use App\Models\Notification;
use App\Models\School;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class NotificationFlowTest extends TestCase
{
    use RefreshDatabase;

    protected $user;

    protected $schoolId = 1;

    protected function setUp(): void
    {
        parent::setUp();

        $school = School::factory()->create();
        $this->schoolId = $school->id;

        $this->user = User::factory()->create([
            'school_id' => $this->schoolId,
            'role' => 'teacher',
        ]);
    }

    public function test_can_get_all_notifications()
    {
        Notification::factory()->count(5)->create([
            'user_id' => $this->user->id,
        ]);

        $response = $this->actingAs($this->user, 'api')
            ->getJson('/api/notifications');

        $response->assertStatus(200)
            ->assertJsonCount(5, 'data');
    }

    public function test_can_filter_notifications_by_read_status()
    {
        Notification::factory()->count(3)->unread()->create([
            'user_id' => $this->user->id,
        ]);

        Notification::factory()->count(2)->read()->create([
            'user_id' => $this->user->id,
        ]);

        $response = $this->actingAs($this->user, 'api')
            ->getJson('/api/notifications?is_read=0');

        $response->assertStatus(200)
            ->assertJsonCount(3, 'data');
    }

    public function test_can_get_unread_count()
    {
        Notification::factory()->count(4)->unread()->create([
            'user_id' => $this->user->id,
        ]);

        Notification::factory()->count(1)->read()->create([
            'user_id' => $this->user->id,
        ]);

        $response = $this->actingAs($this->user, 'api')
            ->getJson('/api/notifications/unread-count');

        $response->assertStatus(200)
            ->assertJson(['count' => 4]);
    }

    public function test_can_create_notification()
    {
        $payload = [
            'user_id' => $this->user->id,
            'type' => 'info',
            'title' => 'Test Notification',
            'message' => 'This is a test notification message.',
        ];

        $response = $this->actingAs($this->user, 'api')
            ->postJson('/api/notifications', $payload);

        $response->assertStatus(201)
            ->assertJsonPath('data.title', 'Test Notification');
    }

    public function test_can_broadcast_notifications()
    {
        $users = User::factory()->count(3)->create(['school_id' => $this->schoolId]);
        $userIds = $users->pluck('id')->toArray();

        $payload = [
            'user_ids' => $userIds,
            'type' => 'announcement',
            'title' => 'Broadcast Test',
            'message' => 'This is a broadcast message.',
        ];

        $response = $this->actingAs($this->user, 'api')
            ->postJson('/api/notifications/broadcast', $payload);

        $response->assertStatus(201)
            ->assertJson(['success' => true]);

        $this->assertDatabaseCount('notifications', 3);
    }

    public function test_can_mark_notification_as_read()
    {
        $notification = Notification::factory()->unread()->create([
            'user_id' => $this->user->id,
        ]);

        $response = $this->actingAs($this->user, 'api')
            ->postJson("/api/notifications/{$notification->id}/read");

        $response->assertStatus(200);

        $this->assertDatabaseHas('notifications', [
            'id' => $notification->id,
            'is_read' => true,
        ]);
    }

    public function test_can_mark_all_notifications_as_read()
    {
        Notification::factory()->count(5)->unread()->create([
            'user_id' => $this->user->id,
        ]);

        $response = $this->actingAs($this->user, 'api')
            ->postJson('/api/notifications/mark-all-read');

        $response->assertStatus(200)
            ->assertJson(['success' => true]);

        $this->assertEquals(0, Notification::where('user_id', $this->user->id)
            ->where('is_read', false)
            ->count());
    }

    public function test_can_delete_notification()
    {
        $notification = Notification::factory()->create([
            'user_id' => $this->user->id,
        ]);

        $response = $this->actingAs($this->user, 'api')
            ->deleteJson("/api/notifications/{$notification->id}");

        $response->assertStatus(200);
        $this->assertDatabaseMissing('notifications', ['id' => $notification->id]);
    }

    public function test_can_delete_all_read_notifications()
    {
        Notification::factory()->count(3)->read()->create([
            'user_id' => $this->user->id,
        ]);

        Notification::factory()->count(2)->unread()->create([
            'user_id' => $this->user->id,
        ]);

        $response = $this->actingAs($this->user, 'api')
            ->deleteJson('/api/notifications/read/all');

        $response->assertStatus(200)
            ->assertJson(['success' => true]);

        $this->assertEquals(2, Notification::where('user_id', $this->user->id)->count());
    }

    public function test_cannot_access_other_users_notifications()
    {
        $otherUser = User::factory()->create(['school_id' => $this->schoolId]);
        $notification = Notification::factory()->create([
            'user_id' => $otherUser->id,
        ]);

        $response = $this->actingAs($this->user, 'api')
            ->postJson("/api/notifications/{$notification->id}/read");

        $response->assertStatus(404);
    }
}
