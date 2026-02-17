# Phase 4: Data Migration Guide

## 📋 Overview

This guide will help you migrate your data from Firebase Firestore to MySQL using the provided scripts.

---

## 🔧 Prerequisites

### 1. Firebase Service Account Key

You need a Firebase service account key to export data from Firestore.

**Steps to get the key:**

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project
3. Go to **Project Settings** (gear icon) → **Service Accounts**
4. Click **Generate New Private Key**
5. Save the JSON file as `firebase-service-account.json`
6. Place it in the `migration-scripts/` directory

### 2. Node.js

- Node.js 14+ installed
- npm package manager

### 3. MySQL Database

- MySQL 8.0+ running
- Database created (`school_management`)
- Laravel migrations completed

---

## 📤 Step 1: Export Data from Firestore

### 1.1 Install Dependencies

```bash
cd migration-scripts
npm install
```

### 1.2 Configure Firebase

Place your `firebase-service-account.json` in the `migration-scripts/` directory.

### 1.3 Run Export Script

```bash
npm run export
```

**What this does:**
- Connects to your Firestore database
- Exports all collections to JSON files
- Saves files to `firestore-export/` directory
- Creates an export summary

**Output:**
```
firestore-export/
├── schools.json
├── users.json
├── sections.json
├── academicSessions.json
├── terms.json
├── classes.json
├── students.json
├── fees.json
├── transactions.json
└── _export_summary.json
```

---

## 📥 Step 2: Import Data to MySQL

### 2.1 Verify Laravel Setup

Ensure your Laravel backend is properly configured:

```bash
cd ../backend

# Check database connection
php artisan db:show

# Verify migrations are run
php artisan migrate:status
```

### 2.2 Run Import Command

```bash
php artisan import:firestore ../migration-scripts/firestore-export
```

**What this does:**
- Reads JSON files from the export directory
- Maps Firestore IDs to MySQL auto-increment IDs
- Imports data in correct order (respecting foreign keys)
- Maintains relationships between entities
- Uses database transactions (rolls back on error)

**Expected Output:**
```
🚀 Starting Firestore data import...

Importing schools...
✅ Imported 1 schools
Importing sections...
✅ Imported 3 sections
Importing users...
✅ Imported 15 users
Importing academic sessions...
✅ Imported 2 academic sessions
Importing terms...
✅ Imported 6 terms
Importing classes...
✅ Imported 10 classes
Importing students...
✅ Imported 150 students
Importing fees...
✅ Imported 20 fees
Importing transactions...
✅ Imported 500 transactions

✅ Import completed successfully!

📊 Import Summary:
────────────────────────────────────────
schools              1 records
sections             3 records
users                15 records
sessions             2 records
terms                6 records
classes              10 records
students             150 records
fees                 20 records
transactions         500 records
────────────────────────────────────────
Total: 707 records
```

---

## ✅ Step 3: Verify Migration

### 3.1 Check Record Counts

```bash
# In MySQL
mysql -u your_username -p school_management

SELECT 
  (SELECT COUNT(*) FROM schools) as schools,
  (SELECT COUNT(*) FROM users) as users,
  (SELECT COUNT(*) FROM sections) as sections,
  (SELECT COUNT(*) FROM students) as students,
  (SELECT COUNT(*) FROM transactions) as transactions;
```

### 3.2 Verify Relationships

```bash
# Check user-section assignments
SELECT COUNT(*) FROM user_section;

# Check transactions with students
SELECT COUNT(*) FROM transactions WHERE student_id IS NOT NULL;

# Check fees by class
SELECT c.class_name, COUNT(f.id) as fee_count
FROM classes c
LEFT JOIN fees f ON c.id = f.class_id
GROUP BY c.id;
```

### 3.3 Test API Endpoints

```bash
# Login
curl -X POST http://localhost:8000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "proprietor@demoschool.com",
    "password": "password"
  }'

# Get students
curl -X GET http://localhost:8000/api/schools/1/students \
  -H "Authorization: Bearer YOUR_TOKEN"

# Get dashboard stats
curl -X GET http://localhost:8000/api/schools/1/transactions-dashboard-stats \
  -H "Authorization: Bearer YOUR_TOKEN"
```

---

## 🔄 Step 4: Handle Migration Issues

### Common Issues

#### Issue 1: Missing Dependencies

**Error:** `Skipping X: dependencies not found`

**Solution:**
- Check that parent records exist in Firestore
- Verify export was complete
- Check field names match (schoolId, sectionId, etc.)

#### Issue 2: Duplicate Emails

**Error:** `Duplicate entry for key 'users.email'`

**Solution:**
```bash
# Reset and try again
php artisan migrate:fresh
php artisan import:firestore ../migration-scripts/firestore-export
```

#### Issue 3: Date Format Issues

**Error:** `Invalid date format`

**Solution:**
- Check Firestore timestamps are being converted correctly
- Verify export script handles Firestore Timestamps

---

## 🔐 Step 5: Update User Passwords

After migration, all users will have the default password `password`.

**Send password reset emails:**

```bash
# Create a command to send reset emails
php artisan make:command SendPasswordResets

# Or manually update passwords in database
# UPDATE users SET password = '$2y$10$...' WHERE email = 'user@example.com';
```

---

## 📊 Step 6: Validate Data Integrity

### 6.1 Financial Calculations

```sql
-- Verify transaction totals
SELECT 
  transaction_type,
  COUNT(*) as count,
  SUM(amount) as total
FROM transactions
GROUP BY transaction_type;

-- Compare with Firestore export
```

### 6.2 Student Counts

```sql
-- Students by class
SELECT 
  c.class_name,
  COUNT(s.id) as student_count
FROM classes c
LEFT JOIN students s ON c.id = s.class_id
GROUP BY c.id;
```

### 6.3 Fee Assignments

```sql
-- Fees by term
SELECT 
  t.term_name,
  COUNT(f.id) as fee_count,
  SUM(f.amount) as total_fees
FROM terms t
LEFT JOIN fees f ON t.id = f.term_id
GROUP BY t.id;
```

---

## 🎯 Step 7: Post-Migration Cleanup

### 7.1 Remove Firebase Dependencies (Optional)

Once migration is verified, you can:

1. **Keep Firebase as backup** (recommended for 1-2 months)
2. **Archive Firestore data**
3. **Update Flutter app** to use new API

### 7.2 Update Flutter App Configuration

```dart
// lib/core/config/api_config.dart
class ApiConfig {
  static const String baseUrl = 'http://your-server.com/api';
  static const String loginEndpoint = '/auth/login';
  // ... other endpoints
}
```

---

## 📝 Migration Checklist

- [ ] Firebase service account key obtained
- [ ] Node.js dependencies installed
- [ ] Firestore data exported successfully
- [ ] Export summary reviewed
- [ ] Laravel database configured
- [ ] Migrations run successfully
- [ ] Data imported to MySQL
- [ ] Record counts verified
- [ ] Relationships validated
- [ ] API endpoints tested
- [ ] Financial calculations verified
- [ ] User passwords handled
- [ ] Flutter app updated (Phase 5)

---

## 🆘 Troubleshooting

### Export Script Issues

**Problem:** `Error: Could not load the default credentials`

**Solution:**
```bash
# Verify firebase-service-account.json exists
ls migration-scripts/firebase-service-account.json

# Check file permissions
chmod 644 migration-scripts/firebase-service-account.json
```

### Import Command Issues

**Problem:** `Class 'App\Console\Commands\ImportFirestoreData' not found`

**Solution:**
```bash
# Clear Laravel cache
php artisan config:clear
php artisan cache:clear
composer dump-autoload
```

**Problem:** `SQLSTATE[23000]: Integrity constraint violation`

**Solution:**
```bash
# Reset database and try again
php artisan migrate:fresh
php artisan import:firestore ../migration-scripts/firestore-export
```

---

## 📞 Support

If you encounter issues:

1. Check the export summary (`_export_summary.json`)
2. Review Laravel logs (`storage/logs/laravel.log`)
3. Verify database constraints
4. Check ID mappings in import command

---

## 🎉 Success Criteria

Migration is successful when:

✅ All records exported from Firestore  
✅ All records imported to MySQL  
✅ Record counts match  
✅ Relationships intact  
✅ API endpoints working  
✅ Financial calculations correct  
✅ No data loss  

---

**Last Updated**: 2025-12-02  
**Phase**: 4 - Data Migration  
**Status**: Ready for execution
