<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Notification;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Validator;

class NotificationController extends Controller
{
    /**
     * Get user's notifications.
     */
    public function index(Request $request)
    {
        $userId = Auth::id();
        $query = Notification::where('user_id', $userId);

        if ($request->has('unread_only') && $request->unread_only == 'true') {
            $query->where('is_read', false);
        }

        if ($request->has('is_read')) {
            $query->where('is_read', $request->boolean('is_read'));
        }

        $notifications = $query->orderBy('created_at', 'desc')->get();

        return response()->json([
            'success' => true,
            'data' => $notifications
        ]);
    }

    /**
     * Get unread notifications count.
     */
    public function unreadCount()
    {
        $count = Notification::where('user_id', Auth::id())->where('is_read', false)->count();
        return response()->json(['success' => true, 'count' => $count]);
    }

    /**
     * Store a new notification.
     */
    public function store(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'user_id' => 'required|exists:users,id',
            'type' => 'required|string',
            'title' => 'required|string',
            'message' => 'required|string',
            'data' => 'nullable|array',
        ]);

        if ($validator->fails()) {
            return response()->json(['success' => false, 'errors' => $validator->errors()], 422);
        }

        $notification = Notification::create($request->all());

        return response()->json([
            'success' => true,
            'data' => $notification
        ], 201);
    }

    /**
     * Mark a notification as read.
     */
    public function markAsRead($id)
    {
        $notification = Notification::where('id', $id)->where('user_id', Auth::id())->firstOrFail();
        $notification->update(['is_read' => true, 'read_at' => now()]);

        return response()->json(['success' => true]);
    }

    /**
     * Mark all notifications as read.
     */
    public function markAllAsRead()
    {
        Notification::where('user_id', Auth::id())
            ->where('is_read', false)
            ->update(['is_read' => true, 'read_at' => now()]);

        return response()->json(['success' => true]);
    }

    /**
     * Broadcast a notification to multiple users (e.g., all parents in a section).
     */
    public function broadcast(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'user_ids' => 'required|array',
            'user_ids.*' => 'exists:users,id',
            'type' => 'required|string',
            'title' => 'required|string',
            'message' => 'required|string',
            'data' => 'nullable|array',
        ]);

        if ($validator->fails()) {
            return response()->json(['success' => false, 'errors' => $validator->errors()], 422);
        }

        $notifications = [];
        foreach ($request->user_ids as $userId) {
            $notifications[] = [
                'user_id' => $userId,
                'type' => $request->type,
                'title' => $request->title,
                'message' => $request->message,
                'data' => json_encode($request->data),
                'created_at' => now(),
                'updated_at' => now(),
            ];
        }

        Notification::insert($notifications);

        return response()->json(['success' => true, 'message' => 'Notifications broadcasted'], 201);
    }

    /**
     * Delete a notification.
     */
    public function destroy($id)
    {
        $notification = Notification::where('id', $id)->where('user_id', Auth::id())->firstOrFail();
        $notification->delete();

        return response()->json(['success' => true]);
    }

    /**
     * Delete all read notifications.
     */
    public function deleteAllRead()
    {
        Notification::where('user_id', Auth::id())->where('is_read', true)->delete();
        return response()->json(['success' => true]);
    }
}
