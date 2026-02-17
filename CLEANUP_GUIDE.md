# 🧹 Code Cleanup Guide - Remove Firebase Dependencies

## 📋 Overview

This guide will help you remove all Firebase-related code and keep only the new Laravel API integration.

---

## ⚠️ IMPORTANT: Backup First!

```bash
# Create a backup branch
git checkout -b backup-before-cleanup
git add .
git commit -m "Backup before Firebase cleanup"

# Create cleanup branch
git checkout -b cleanup-firebase-code
```

---

## 🗑️ Files to DELETE

### Firebase Services (Old - No longer needed)

```
lib/core/services/
├── auth_service.dart                    ❌ DELETE (use auth_service_api.dart)
├── transaction_service.dart             ❌ DELETE (use transaction_service_api.dart)
├── student_service.dart                 ❌ DELETE (use student_service_api.dart)
├── section_service.dart                 ❌ DELETE (use section_service_api.dart)
├── class_service.dart                   ❌ DELETE (use class_service_api.dart)
├── fee_service.dart                     ❌ DELETE (use fee_service_api.dart)
├── academic_session_service.dart        ❌ DELETE
├── term_service.dart                    ❌ DELETE
├── user_service.dart                    ❌ DELETE
├── school_service.dart                  ❌ DELETE
├── subscription_service.dart            ❌ DELETE (if not needed)
├── database_service.dart                ❌ DELETE
└── firestore_paths.dart                 ❌ DELETE
```

### Temporary/Helper Files

```
lib/screens/dashboard/
└── _loading_state_helper.dart           ❌ DELETE (if exists)
```

---

## ✅ Files to KEEP

### New API Services (Keep these!)

```
lib/core/services/
├── api_service.dart                     ✅ KEEP
├── auth_service_api.dart                ✅ KEEP
├── transaction_service_api.dart         ✅ KEEP
├── student_service_api.dart             ✅ KEEP
├── section_service_api.dart             ✅ KEEP
├── class_service_api.dart               ✅ KEEP
└── fee_service_api.dart                 ✅ KEEP
```

### Configuration & Utilities

```
lib/core/
├── config/
│   └── api_config.dart                  ✅ KEEP
├── utils/
│   ├── storage_helper.dart              ✅ KEEP
│   ├── app_theme.dart                   ✅ KEEP
│   ├── constants.dart                   ✅ KEEP
│   ├── formatters.dart                  ✅ KEEP
│   └── validators.dart                  ✅ KEEP
└── models/                              ✅ KEEP (all models)
```

---

## 🔧 Dependencies to REMOVE from pubspec.yaml

### Remove Firebase Dependencies:

```yaml
# REMOVE THESE:
dependencies:
  firebase_core: ^3.8.1              ❌ REMOVE
  firebase_auth: ^5.3.3              ❌ REMOVE
  cloud_firestore: ^5.5.0            ❌ REMOVE
  firebase_storage: ^12.3.6          ❌ REMOVE (if present)
```

### Keep These:

```yaml
# KEEP THESE:
dependencies:
  http: ^1.1.0                       ✅ KEEP
  shared_preferences: ^2.5.3         ✅ KEEP
  # ... all other non-Firebase packages
```

---

## 📝 Step-by-Step Cleanup Process

### Step 1: Delete Firebase Service Files

```bash
# Navigate to services directory
cd lib/core/services

# Delete old Firebase services
rm auth_service.dart
rm transaction_service.dart
rm student_service.dart
rm section_service.dart
rm class_service.dart
rm fee_service.dart
rm academic_session_service.dart
rm term_service.dart
rm user_service.dart
rm school_service.dart
rm subscription_service.dart
rm database_service.dart
rm firestore_paths.dart
```

### Step 2: Remove Firebase from pubspec.yaml

Edit `pubspec.yaml` and remove:

```yaml
# DELETE THESE LINES:
  firebase_core: ^3.8.1
  firebase_auth: ^5.3.3
  cloud_firestore: ^5.5.0
```

### Step 3: Delete firebase_options.dart

```bash
rm lib/firebase_options.dart
```

### Step 4: Remove Firebase Initialization from main.dart

**Before:**
```dart
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}
```

**After:**
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}
```

### Step 5: Update Import Statements in All Screens

Find and replace across all files:

**Old Imports (Remove):**
```dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/services/auth_service.dart';
import '../core/services/transaction_service.dart';
import '../core/services/student_service.dart';
// etc.
```

**New Imports (Use):**
```dart
import '../core/services/auth_service_api.dart';
import '../core/services/transaction_service_api.dart';
import '../core/services/student_service_api.dart';
import '../core/services/api_service.dart';
// etc.
```

### Step 6: Clean Flutter Cache

```bash
# Clean build cache
flutter clean

# Get dependencies
flutter pub get

# Rebuild
flutter run
```

---

## 🔍 Find Remaining Firebase References

### Search for Firebase Usage:

```bash
# Search for Firebase imports
grep -r "import 'package:firebase" lib/

# Search for Firestore usage
grep -r "FirebaseFirestore" lib/

# Search for Firebase Auth usage
grep -r "FirebaseAuth" lib/

# Search for old service imports
grep -r "auth_service.dart" lib/
grep -r "transaction_service.dart" lib/
grep -r "student_service.dart" lib/
```

---

## 📋 Cleanup Checklist

### Files:
- [ ] Deleted `auth_service.dart`
- [ ] Deleted `transaction_service.dart`
- [ ] Deleted `student_service.dart`
- [ ] Deleted `section_service.dart`
- [ ] Deleted `class_service.dart`
- [ ] Deleted `fee_service.dart`
- [ ] Deleted `academic_session_service.dart`
- [ ] Deleted `term_service.dart`
- [ ] Deleted `user_service.dart`
- [ ] Deleted `school_service.dart`
- [ ] Deleted `subscription_service.dart`
- [ ] Deleted `database_service.dart`
- [ ] Deleted `firestore_paths.dart`
- [ ] Deleted `firebase_options.dart`
- [ ] Deleted `_loading_state_helper.dart` (if exists)

### Dependencies:
- [ ] Removed `firebase_core` from pubspec.yaml
- [ ] Removed `firebase_auth` from pubspec.yaml
- [ ] Removed `cloud_firestore` from pubspec.yaml
- [ ] Removed `firebase_storage` from pubspec.yaml (if present)
- [ ] Kept `http` package
- [ ] Kept `shared_preferences` package

### Code Updates:
- [ ] Removed Firebase initialization from `main.dart`
- [ ] Updated all import statements
- [ ] Replaced Firebase service calls with API service calls
- [ ] Tested login functionality
- [ ] Tested data loading
- [ ] No Firebase references remaining

### Testing:
- [ ] App compiles without errors
- [ ] No Firebase import errors
- [ ] API services working
- [ ] Login works
- [ ] Dashboard loads
- [ ] All features functional

---

## 🚨 Common Issues After Cleanup

### Issue 1: Import Errors

**Error:** `Target of URI doesn't exist: 'package:firebase_core/firebase_core.dart'`

**Solution:**
```bash
flutter clean
flutter pub get
```

### Issue 2: Missing Service Methods

**Error:** `The method 'someMethod' isn't defined for the class 'AuthService'`

**Solution:**
- Update import to use `AuthServiceApi`
- Update method calls to match new API service

### Issue 3: Undefined Class

**Error:** `Undefined class 'FirebaseAuth'`

**Solution:**
- Remove Firebase import
- Replace with API service call

---

## 📊 Before vs After

### Before Cleanup:
```
lib/core/services/
├── auth_service.dart (Firebase)
├── auth_service_api.dart (API)
├── transaction_service.dart (Firebase)
├── transaction_service_api.dart (API)
├── student_service.dart (Firebase)
├── student_service_api.dart (API)
└── ... (duplicates)

Dependencies:
- firebase_core
- firebase_auth
- cloud_firestore
- http
```

### After Cleanup:
```
lib/core/services/
├── api_service.dart
├── auth_service_api.dart
├── transaction_service_api.dart
├── student_service_api.dart
├── section_service_api.dart
├── class_service_api.dart
└── fee_service_api.dart

Dependencies:
- http
- shared_preferences
```

---

## ✅ Verification Commands

```bash
# Check for Firebase references
grep -r "firebase" lib/ --exclude-dir=.dart_tool

# Check for old service imports
grep -r "auth_service.dart" lib/
grep -r "transaction_service.dart" lib/

# Verify app compiles
flutter analyze

# Run app
flutter run
```

---

## 🎯 Expected Results

After cleanup:
- ✅ No Firebase dependencies
- ✅ Smaller app size
- ✅ Faster build times
- ✅ Only API services remain
- ✅ All features working
- ✅ No compilation errors

---

## 💾 Save Your Work

```bash
# After successful cleanup
git add .
git commit -m "Remove Firebase dependencies, keep only Laravel API integration"
git push origin cleanup-firebase-code
```

---

## 📞 Need Help?

If you encounter issues:

1. Check error messages carefully
2. Verify all imports updated
3. Ensure API services are used
4. Run `flutter clean` and `flutter pub get`
5. Check that backend server is running

---

**Last Updated**: 2025-12-02  
**Status**: Ready for cleanup  
**Estimated Time**: 30-60 minutes
