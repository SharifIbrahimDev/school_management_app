# 🧪 TESTING & DEPLOYMENT GUIDE

## Date: 2025-12-03 12:14

---

## 📋 **PRE-TESTING CHECKLIST**

### Backend Requirements
- [ ] Laravel backend is running on `http://localhost:8000`
- [ ] Database is migrated and seeded
- [ ] API routes are accessible
- [ ] CORS is configured for Flutter app

### Frontend Requirements
- [ ] Flutter dependencies are installed (`flutter pub get`)
- [ ] No critical analyze errors (`flutter analyze`)
- [ ] App builds successfully (`flutter build`)

---

## 🚀 **STARTING THE BACKEND**

### Option 1: Using Laravel Artisan
```bash
cd path/to/laravel/backend
php artisan serve
```

### Option 2: Using Docker (if configured)
```bash
cd path/to/laravel/backend
docker-compose up
```

### Verify Backend is Running
```bash
# Test API endpoint
curl http://localhost:8000/api/health

# Or in PowerShell
Invoke-WebRequest -Uri http://localhost:8000/api/health
```

---

## 🧪 **TESTING PLAN**

### Phase 1: Authentication Testing (Critical)

#### Test 1.1: Login
1. Start the Flutter app
2. Navigate to Login screen
3. Enter credentials: `proprietor@demoschool.com` / `password`
4. **Expected**: Successful login, redirect to dashboard
5. **Verify**: Token is stored, user data is loaded

#### Test 1.2: Session Persistence
1. Close and reopen the app
2. **Expected**: User remains logged in
3. **Verify**: Dashboard loads without login prompt

#### Test 1.3: Logout
1. Navigate to Profile screen
2. Click "Sign Out"
3. **Expected**: Redirect to login screen
4. **Verify**: Token is cleared

### Phase 2: Dashboard Testing

#### Test 2.1: Proprietor Dashboard
1. Login as proprietor
2. **Verify**:
   - Sections are displayed
   - Academic sessions are displayed
   - Terms are displayed
   - Classes are displayed
   - Transaction statistics are shown

#### Test 2.2: Principal Dashboard
1. Login as principal
2. **Verify**:
   - Only assigned sections are shown
   - Dashboard statistics are correct
   - Navigation works

### Phase 3: CRUD Operations Testing

#### Test 3.1: Student Management
1. Navigate to Students list
2. **Create**: Click "Add Student", fill form, submit
3. **Read**: Verify student appears in list
4. **Update**: Click student, edit details, save
5. **Delete**: Delete student, confirm removal

#### Test 3.2: Class Management
1. Navigate to Classes list
2. **Create**: Add new class
3. **Read**: View class details
4. **Update**: Edit class information
5. **Assign**: Assign teacher to class

#### Test 3.3: Transaction Management
1. Navigate to Transactions
2. **Create**: Add new transaction
3. **Read**: View transaction list
4. **Filter**: Test session/term filters
5. **Report**: Generate transaction report

#### Test 3.4: Fee Management
1. Navigate to Fees
2. **Create**: Add new fee
3. **Read**: View fee list
4. **Filter**: Test filters
5. **Detail**: View fee details

#### Test 3.5: User Management
1. Navigate to Users (as proprietor)
2. **Create**: Add new user
3. **Read**: View user list
4. **Search**: Test search functionality
5. **Filter**: Test role filter

### Phase 4: Error Handling Testing

#### Test 4.1: Network Errors
1. Stop the backend server
2. Try to perform any action
3. **Expected**: Appropriate error message
4. **Verify**: App doesn't crash

#### Test 4.2: Invalid Data
1. Try to submit forms with invalid data
2. **Expected**: Validation errors shown
3. **Verify**: Form doesn't submit

#### Test 4.3: Permission Errors
1. Login as non-proprietor
2. Try to access proprietor-only features
3. **Expected**: Access denied message
4. **Verify**: No unauthorized access

### Phase 5: Edge Cases Testing

#### Test 5.1: Empty States
1. Navigate to screens with no data
2. **Expected**: "No data found" messages
3. **Verify**: No crashes or errors

#### Test 5.2: Large Data Sets
1. Create multiple entries (50+)
2. **Expected**: Smooth scrolling
3. **Verify**: Performance is acceptable

#### Test 5.3: Concurrent Operations
1. Perform multiple actions quickly
2. **Expected**: All actions complete
3. **Verify**: No race conditions

---

## 📊 **TEST RESULTS TEMPLATE**

### Test Execution Log

| Test ID | Test Name | Status | Notes |
|---------|-----------|--------|-------|
| 1.1 | Login | ⏳ Pending | |
| 1.2 | Session Persistence | ⏳ Pending | |
| 1.3 | Logout | ⏳ Pending | |
| 2.1 | Proprietor Dashboard | ⏳ Pending | |
| 2.2 | Principal Dashboard | ⏳ Pending | |
| 3.1 | Student CRUD | ⏳ Pending | |
| 3.2 | Class CRUD | ⏳ Pending | |
| 3.3 | Transaction CRUD | ⏳ Pending | |
| 3.4 | Fee CRUD | ⏳ Pending | |
| 3.5 | User CRUD | ⏳ Pending | |
| 4.1 | Network Errors | ⏳ Pending | |
| 4.2 | Invalid Data | ⏳ Pending | |
| 4.3 | Permission Errors | ⏳ Pending | |
| 5.1 | Empty States | ⏳ Pending | |
| 5.2 | Large Data Sets | ⏳ Pending | |
| 5.3 | Concurrent Operations | ⏳ Pending | |

**Legend**: ✅ Pass | ❌ Fail | ⏳ Pending | ⚠️ Partial

---

## 🐛 **KNOWN ISSUES & WORKAROUNDS**

### Issue 1: API Connection Errors
**Symptom**: "Failed to connect to backend"
**Solution**: 
1. Verify backend is running on port 8000
2. Check `lib/core/services/*_api.dart` for correct baseUrl
3. Ensure CORS is configured

### Issue 2: Token Expiration
**Symptom**: Sudden logout or 401 errors
**Solution**:
1. Implement token refresh mechanism
2. Check token expiration time in backend
3. Add automatic re-login

### Issue 3: ID Conversion Errors
**Symptom**: "Invalid ID" errors
**Solution**:
1. Verify int.tryParse() usage
2. Check API response format
3. Ensure IDs are strings in models

---

## 🔧 **DEBUGGING TIPS**

### Enable Debug Logging
```dart
// In API services, add:
print('API Request: $url');
print('API Response: ${response.body}');
```

### Check Network Traffic
1. Use Flutter DevTools
2. Enable network profiling
3. Inspect API calls and responses

### Monitor Backend Logs
```bash
# In Laravel backend directory
tail -f storage/logs/laravel.log
```

---

## 📱 **RUNNING THE APP**

### Development Mode
```bash
# Web
flutter run -d chrome

# Android
flutter run -d android

# iOS
flutter run -d ios
```

### Build for Production
```bash
# Web
flutter build web

# Android
flutter build apk

# iOS
flutter build ios
```

---

## ✅ **ACCEPTANCE CRITERIA**

The migration is considered successful when:

1. **Authentication**
   - ✅ Users can login
   - ✅ Sessions persist
   - ✅ Logout works

2. **Data Display**
   - ✅ All dashboards load data
   - ✅ Lists display correctly
   - ✅ Details show complete information

3. **CRUD Operations**
   - ✅ Create operations work
   - ✅ Read operations work
   - ✅ Update operations work
   - ✅ Delete operations work

4. **Error Handling**
   - ✅ Network errors handled gracefully
   - ✅ Validation errors shown
   - ✅ Permission errors handled

5. **Performance**
   - ✅ App loads in < 3 seconds
   - ✅ Smooth scrolling
   - ✅ No memory leaks

---

## 🚀 **DEPLOYMENT CHECKLIST**

### Pre-Deployment
- [ ] All tests pass
- [ ] No critical errors in analyze
- [ ] Backend is production-ready
- [ ] Environment variables configured
- [ ] API keys secured

### Deployment Steps
1. [ ] Build production app
2. [ ] Deploy backend to server
3. [ ] Update API URLs in app
4. [ ] Test on production environment
5. [ ] Monitor for errors

### Post-Deployment
- [ ] Monitor error logs
- [ ] Check performance metrics
- [ ] Gather user feedback
- [ ] Plan next iteration

---

## 📞 **SUPPORT & TROUBLESHOOTING**

### Common Commands
```bash
# Clean and rebuild
flutter clean
flutter pub get
flutter run

# Check for issues
flutter analyze
flutter doctor

# View logs
flutter logs
```

### Getting Help
1. Check error logs
2. Review API documentation
3. Consult migration summary
4. Test with Postman/curl

---

*Generated: 2025-12-03 12:14*
*Migration Status: 75% Complete*
*Ready for Testing: Yes*
