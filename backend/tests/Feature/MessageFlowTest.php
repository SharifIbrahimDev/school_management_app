<?php

namespace Tests\Feature;

use App\Models\Message;
use App\Models\School;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class MessageFlowTest extends TestCase
{
    use RefreshDatabase;

    protected $sender;

    protected $recipient;

    protected $schoolId = 1;

    protected function setUp(): void
    {
        parent::setUp();

        $school = School::factory()->create();
        $this->schoolId = $school->id;

        $this->sender = User::factory()->create([
            'school_id' => $this->schoolId,
            'role' => 'teacher',
        ]);

        $this->recipient = User::factory()->create([
            'school_id' => $this->schoolId,
            'role' => 'parent',
        ]);
    }

    public function test_can_send_message()
    {
        $payload = [
            'recipient_id' => $this->recipient->id,
            'subject' => 'Test Subject',
            'body' => 'This is a test message body.',
        ];

        $response = $this->actingAs($this->sender, 'api')
            ->postJson('/api/messages', $payload);

        $response->assertStatus(201)
            ->assertJsonPath('data.sender_id', $this->sender->id)
            ->assertJsonPath('data.recipient_id', $this->recipient->id)
            ->assertJsonPath('data.subject', 'Test Subject')
            ->assertJsonPath('data.body', 'This is a test message body.');

        $this->assertDatabaseHas('messages', [
            'sender_id' => $this->sender->id,
            'recipient_id' => $this->recipient->id,
            'subject' => 'Test Subject',
        ]);
    }

    public function test_cannot_send_message_to_self()
    {
        $payload = [
            'recipient_id' => $this->sender->id,
            'subject' => 'Test',
            'body' => 'Test message',
        ];

        $response = $this->actingAs($this->sender, 'api')
            ->postJson('/api/messages', $payload);

        $response->assertStatus(422);
    }

    public function test_can_view_inbox()
    {
        Message::factory()->count(3)->create([
            'recipient_id' => $this->sender->id,
        ]);

        $response = $this->actingAs($this->sender, 'api')
            ->getJson('/api/messages');

        $response->assertStatus(200)
            ->assertJsonStructure(['success', 'data']);
        
        $this->assertCount(3, $response->json('data'));
    }

    public function test_can_view_sent_messages()
    {
        Message::factory()->count(2)->create([
            'sender_id' => $this->sender->id,
        ]);

        $response = $this->actingAs($this->sender, 'api')
            ->getJson('/api/messages');

        $response->assertStatus(200)
            ->assertJsonStructure(['success', 'data']);

        $this->assertCount(2, $response->json('data'));
    }

    public function test_can_get_unread_count()
    {
        Message::factory()->count(2)->unread()->create([
            'recipient_id' => $this->sender->id,
        ]);

        Message::factory()->count(1)->read()->create([
            'recipient_id' => $this->sender->id,
        ]);

        $response = $this->actingAs($this->sender, 'api')
            ->getJson('/api/messages/unread-count');

        $response->assertStatus(200)
            ->assertJson(['count' => 2]);
    }

    public function test_can_view_message_and_mark_as_read()
    {
        $message = Message::factory()->unread()->create([
            'recipient_id' => $this->sender->id,
        ]);

        $response = $this->actingAs($this->sender, 'api')
            ->postJson("/api/messages/{$message->id}/read");

        $response->assertStatus(200);

        $this->assertDatabaseHas('messages', [
            'id' => $message->id,
            'is_read' => true,
        ]);
    }

    public function test_cannot_view_unauthorized_message()
    {
        $otherUser = User::factory()->create(['school_id' => $this->schoolId]);
        $message = Message::factory()->create([
            'sender_id' => $otherUser->id,
            'recipient_id' => $this->recipient->id,
        ]);

        $response = $this->actingAs($this->sender, 'api')
            ->postJson("/api/messages/{$message->id}/read");

        $response->assertStatus(404);
    }

    public function test_can_delete_message()
    {
        $message = Message::factory()->create([
            'sender_id' => $this->sender->id,
        ]);

        $response = $this->actingAs($this->sender, 'api')
            ->deleteJson("/api/messages/{$message->id}");

        $response->assertStatus(200);
        $this->assertSoftDeleted('messages', ['id' => $message->id]);
    }

    public function test_can_get_users_to_message()
    {
        User::factory()->count(5)->create(['school_id' => $this->schoolId]);

        $response = $this->actingAs($this->sender, 'api')
            ->getJson('/api/messages/contacts');

        $response->assertStatus(200)
            ->assertJsonStructure(['success', 'data']);
    }
}
