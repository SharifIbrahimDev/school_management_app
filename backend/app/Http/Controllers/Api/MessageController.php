<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Message;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Facades\DB;

class MessageController extends Controller
{
    /**
     * Get unique conversations (latest message with each user).
     */
    public function index()
    {
        $userId = Auth::id();

        // Subquery to get the latest message ID for each conversation
        $latestMessageIds = Message::where('sender_id', $userId)
            ->orWhere('recipient_id', $userId)
            ->select(DB::raw('MAX(id) as id'))
            ->groupBy(DB::raw('CASE WHEN sender_id = ' . $userId . ' THEN recipient_id ELSE sender_id END'))
            ->pluck('id');

        $conversations = Message::with(['sender', 'recipient'])
            ->whereIn('id', $latestMessageIds)
            ->orderBy('created_at', 'desc')
            ->get();

        return response()->json([
            'success' => true,
            'data' => $conversations
        ]);
    }

    /**
     * Get full chat history with another user.
     */
    public function getConversation($otherUserId)
    {
        $userId = Auth::id();

        $messages = Message::with(['sender', 'recipient'])
            ->where(function ($query) use ($userId, $otherUserId) {
                $query->where('sender_id', $userId)->where('recipient_id', $otherUserId);
            })
            ->orWhere(function ($query) use ($userId, $otherUserId) {
                $query->where('sender_id', $otherUserId)->where('recipient_id', $userId);
            })
            ->orderBy('created_at', 'asc')
            ->get();

        return response()->json([
            'success' => true,
            'data' => $messages
        ]);
    }

    /**
     * Send a new message.
     */
    public function store(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'recipient_id' => 'required|exists:users,id',
            'body' => 'required|string',
            'subject' => 'nullable|string|max:255',
            'parent_message_id' => 'nullable|exists:messages,id',
        ]);

        if ($validator->fails()) {
            return response()->json(['success' => false, 'errors' => $validator->errors()], 422);
        }

        if (Auth::id() == $request->recipient_id) {
            return response()->json(['success' => false, 'message' => 'Cannot send message to yourself'], 422);
        }

        $userId = Auth::id();
        $message = Message::create([
            'sender_id' => $userId,
            'recipient_id' => $request->recipient_id,
            'body' => $request->body,
            'subject' => $request->subject,
            'parent_message_id' => $request->parent_message_id,
        ]);

        return response()->json([
            'success' => true,
            'data' => $message
        ], 201);
    }

    /**
     * Mark a message as read.
     */
    public function markRead($id)
    {
        $userId = Auth::id();
        $message = Message::where('id', $id)->where('recipient_id', $userId)->firstOrFail();
        
        $message->update([
            'is_read' => true,
            'read_at' => now(),
        ]);

        return response()->json(['success' => true]);
    }

    /**
     * Remove the specified resource from storage.
     */
    public function destroy($id)
    {
        $userId = Auth::id();
        $message = Message::where('id', $id)
            ->where(function($query) use ($userId) {
                $query->where('sender_id', $userId)->orWhere('recipient_id', $userId);
            })
            ->firstOrFail();

        $message->delete();

        return response()->json(['success' => true, 'message' => 'Message deleted']);
    }

    /**
     * List available contacts (e.g., teachers for parents, parents for teachers).
     */
    public function getContacts()
    {
        $user = Auth::user();
        
        // For simplicity, list all users in the same school for now
        // But we could filter based on roles and class associations
        $contacts = User::where('school_id', $user->school_id)
            ->where('id', '!=', $user->id)
            ->get();

        return response()->json([
            'success' => true,
            'data' => $contacts
        ]);
    }

    /**
     * Get unread messages count.
     */
    public function unreadCount()
    {
        $count = Message::where('recipient_id', Auth::id())->where('is_read', false)->count();
        return response()->json(['success' => true, 'count' => $count]);
    }
}
