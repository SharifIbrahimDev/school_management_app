# School Management App

A comprehensive, multi-role mobile application for managing school operations, built with Flutter and Laravel.

## Core Features

### 🎓 Academic Management
- **Teacher Dashboard**: Quick access to attendance, syllabus, lesson plans, and daily schedule.
- **Syllabus Tracking**: Create and track syllabus topics by class and subject.
- **Lesson Plans**: Teachers submit detailed weekly plans; Principals review, approve, or reject them.
- **Timetable**: Integration for viewing daily class schedules.
- **Exams & Results**: create exams, record scores, and supports bulk result upload via CSV.

### 💰 Financial Management (Bursar)
- **Fee Collection**: Record payments, track outstanding balances.
- **Digital Receipts**: Generate and share professional PDF receipts.
- **Debt Recovery**: Automated lists of debtors with one-tap WhatsApp/SMS payment reminders.
- **Financial Reporting**: Detailed transaction logs and summaries.

### 👥 Student & User Management
- **Student Profiles**: Comprehensive records including health, academic history, and parent details.
- **Onboarding**: Streamlined school registration and setup.
- **Role-Based Access**: Specialized interfaces for Admins, Principals, Teachers, Bursars, and Parents.

## Technical Stack
- **Frontend**: Flutter (Dart) - utilizing Provider for state management.
- **Backend**: Laravel (PHP) - MySQL database.
- **Design**: Modern Glassmorphic UI with premium Islamic theme aesthetics.

## Getting Started

1.  **Backend Setup**:
    - Deploy the Laravel backend.
    - Configure `.env` with database credentials.
    - Run migrations: `php artisan migrate`.

2.  **Frontend Setup**:
    - Install dependencies: `flutter pub get`.
    - Run the app: `flutter run`.

## Build
To generate a release APK:
```bash
flutter build apk --release
```
