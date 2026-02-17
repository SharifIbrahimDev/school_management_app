# 🚀 QUICK START GUIDE - School Management App Migration

## ⚡ Get Started in 5 Minutes

This guide will get your migrated School Management App running quickly.

---

## 📋 Prerequisites

- ✅ PHP 8.4+ installed
- ✅ Composer installed
- ✅ MySQL 8.0+ installed
- ✅ Node.js 14+ installed (for data migration)
- ✅ Flutter 3.x installed

---

## 🎯 Step 1: Backend Setup (2 minutes)

```bash
# Navigate to backend
cd backend

# Install dependencies
composer install

# Copy environment file
cp .env.example .env

# Edit .env file and set database credentials:
# DB_DATABASE=school_management
# DB_USERNAME=your_username
# DB_PASSWORD=your_password

# Generate application key
php artisan key:generate

# Run migrations
php artisan migrate

# Seed demo data
php artisan db:seed

# Start server
php artisan serve
```

**✅ Backend is now running at:** `http://localhost:8000`

---

## 🧪 Step 2: Test API (1 minute)

### Test Login Endpoint:

```bash
curl -X POST http://localhost:8000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"proprietor@demoschool.com","password":"password"}'
```

**Expected Response:**
```json
{
  "success": true,
  "data": {
    "token": "eyJ0eXAiOiJKV1QiLCJhbGc...",
    "user": {
      "id": 1,
      "full_name": "School Proprietor",
      "email": "proprietor@demoschool.com",
      "role": "proprietor"
    }
  }
}
```

### Test Dashboard Stats:

```bash
curl -X GET http://localhost:8000/api/schools/1/transactions-dashboard-stats \
  -H "Authorization: Bearer YOUR_TOKEN_HERE"
```

---

## 📱 Step 3: Flutter Setup (2 minutes)

```bash
# Navigate to project root
cd ..

# Install Flutter dependencies
flutter pub get

# Update API URL
# Edit: lib/core/config/api_config.dart
# Change: static const String devUrl = 'http://localhost:8000/api';
# To: static const String devUrl = 'http://YOUR_COMPUTER_IP:8000/api';

# Run app
flutter run
```

---

## 🔄 Step 4: Migrate Your Data (Optional)

If you have existing Firebase data:

```bash
# 1. Get Firebase service account key
# - Go to Firebase Console
# - Project Settings → Service Accounts
# - Generate New Private Key
# - Save as: migration-scripts/firebase-service-account.json

# 2. Export from Firestore
cd migration-scripts
npm install
npm run export

# 3. Import to MySQL
cd ../backend
php artisan import:firestore
```

---

## 🎨 Step 5: Update Flutter Screens

Follow the examples in `FLUTTER_MIGRATION_GUIDE.md` to update your screens.

### Quick Example - Login Screen:

```dart
import 'package:your_app/core/services/auth_service_api.dart';

final authService = AuthServiceApi();

Future<void> _handleLogin() async {
  try {
    final user = await authService.login(
      _emailController.text,
      _passwordController.text,
    );
    Navigator.pushReplacementNamed(context, '/dashboard');
  } catch (e) {
    // Show error
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Login failed: $e')),
    );
  }
}
```

---

## 📊 Demo Credentials

After running `php artisan db:seed`, you can login with:

| Role | Email | Password |
|------|-------|----------|
| Proprietor | proprietor@demoschool.com | password |
| Principal | principal@demoschool.com | password |
| Bursar | bursar@demoschool.com | password |

---

## 🔧 Common Commands

### Backend:

```bash
# Start server
php artisan serve

# Run migrations
php artisan migrate

# Reset database
php artisan migrate:fresh --seed

# View routes
php artisan route:list

# Clear cache
php artisan cache:clear
php artisan config:clear
```

### Flutter:

```bash
# Get dependencies
flutter pub get

# Run app
flutter run

# Build APK
flutter build apk

# Analyze code
flutter analyze
```

---

## 📚 Available Services

All services are ready to use in your Flutter app:

```dart
// Authentication
import 'package:your_app/core/services/auth_service_api.dart';
final authService = AuthServiceApi();

// Transactions
import 'package:your_app/core/services/transaction_service_api.dart';
final transactionService = TransactionServiceApi();

// Students
import 'package:your_app/core/services/student_service_api.dart';
final studentService = StudentServiceApi();

// Sections
import 'package:your_app/core/services/section_service_api.dart';
final sectionService = SectionServiceApi();

// Classes
import 'package:your_app/core/services/class_service_api.dart';
final classService = ClassServiceApi();

// Fees
import 'package:your_app/core/services/fee_service_api.dart';
final feeService = FeeServiceApi();
```

---

## 🧪 Testing Endpoints

Use the Postman collection:

1. Import: `backend/School_Management_API.postman_collection.json`
2. Set variables:
   - `base_url`: `http://localhost:8000/api`
   - `token`: (from login response)
   - `school_id`: `1`
3. Test all endpoints!

---

## 🆘 Troubleshooting

### Backend Issues:

**Error: "Could not find driver"**
```bash
# Install PHP MySQL extension
# Windows: Enable php_pdo_mysql in php.ini
# Linux: sudo apt-get install php-mysql
```

**Error: "Access denied for user"**
```bash
# Check .env database credentials
# Create database: CREATE DATABASE school_management;
```

### Flutter Issues:

**Error: "Failed host lookup"**
```bash
# Use your computer's IP address instead of localhost
# Find IP: ipconfig (Windows) or ifconfig (Linux/Mac)
# Update lib/core/config/api_config.dart
```

**Error: "Connection refused"**
```bash
# Make sure Laravel server is running
# Check firewall settings
```

---

## 📖 Full Documentation

For detailed information, see:

- **MIGRATION_INFRASTRUCTURE_COMPLETE.md** - Complete overview
- **FLUTTER_MIGRATION_GUIDE.md** - Screen update guide
- **DATA_MIGRATION_GUIDE.md** - Data migration steps
- **BACKEND_COMPLETE.md** - Backend documentation
- **QUICK_REFERENCE.md** - Command cheat sheet

---

## ✅ Success Checklist

- [ ] Backend server running
- [ ] Database migrated
- [ ] Demo data seeded
- [ ] API login working
- [ ] Flutter app running
- [ ] Can see login screen
- [ ] Ready to update screens!

---

## 🎉 You're All Set!

Your School Management App backend is now running with:

✅ 65 API endpoints  
✅ Complete database  
✅ Demo data  
✅ 9 Flutter services  
✅ Full documentation  

**Next**: Update your Flutter screens using the migration guide!

---

**Need Help?** Check the documentation files or review the code examples.

**Ready to Deploy?** See Phase 7 in MIGRATION_PLAN_LARAVEL.md

---

**Last Updated**: 2025-12-02  
**Status**: Ready to Use 🚀
