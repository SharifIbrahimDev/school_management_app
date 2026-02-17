# School Management App - Testing Guide

**Version**: 1.0  
**Last Updated**: December 15, 2025  
**App Type**: Flutter Web + Laravel Backend

## Table of Contents
1. [Prerequisites](#prerequisites)
2. [Quick Start](#quick-start)
3. [User Roles & Access](#user-roles--access)
4. [Testing Scenarios](#testing-scenarios)
5. [Backend API Testing](#backend-api-testing)
6. [Known Issues & Workarounds](#known-issues--workarounds)

---

## Prerequisites

### Backend Setup
1. **Database**: MySQL/MariaDB running
2. **Laravel Backend**: 
   ```bash
   cd backend
   php artisan serve
   ```
3. **Database Migrations**: All migrations should be run
   ```bash
   php artisan migrate
   ```

### Frontend Setup
1. **Flutter**: Version 3.35.6 or higher
2. **Chrome**: For web testing
3. **Dependencies**: Run `flutter pub get`

### Environment Configuration
- **Backend URL**: Update `lib/core/config/api_config.dart` with your backend URL
- **Database**: Ensure `.env` file in backend has correct database credentials

---

## Quick Start

### 1. Start Backend Server
```bash
cd backend
php artisan serve
# Server runs at http://localhost:8000
```

### 2. Run Flutter App
```bash
flutter run -d chrome
# OR
flutter run -d web-server --web-port 8080
```

### 3. Access the App
- **URL**: `http://localhost:8080` (web-server) or auto-opened Chrome window
- **Login**: Use test credentials or register a new account

---

## User Roles & Access

### 1. Proprietor
**Highest Level Access** - Full system control

**Capabilities**:
- ✅ View all sections, sessions, classes
- ✅ Manage users (add/edit/delete)
- ✅ Assign sections to staff
- ✅ Create sections, sessions, terms, classes
- ✅ View complete financial reports
- ✅ Manage fees across all sections
- ✅ Record transactions
- ✅ Generate comprehensive reports

**Dashboard Features**:
- Financial overview (all sections)
- Section selector with "All Sections" option
- Quick actions for all management tasks
- Transaction history across entire school

### 2. Principal
**Section-Level Management**

**Capabilities**:
- ✅ Manage assigned sections only
- ✅ View/edit students in assigned sections
- ✅ Create classes and terms
- ✅ View financial reports for assigned sections
- ✅ Manage fees for assigned sections
- ✅ Record transactions

**Dashboard Features**:
- Financial overview (assigned sections)
- Section dropdown (assigned sections only)
- Student and class management
- Transaction recording for section

### 3. Bursar
**Financial Management Focus**

**Capabilities**:
- ✅ View/manage financial data for assigned sections
- ✅ Record income and expenses
- ✅ Generate financial reports
- ✅ Manage fee structures
- ✅ Assign fees to students/classes
- ✅ View transaction history

**Dashboard Features**:
- Comprehensive financial charts
- Income vs Expenses tracking
- Cash/Bank balance monitoring
- Quick transaction recording

### 4. Teacher
**Class-Specific Access**

**Capabilities**:
- ✅ View assigned classes
- ✅ View student lists
- ✅ View student details
- ✅ Limited financial view (class fees)

**Dashboard Features**:
- Class overview
- Student list for assigned classes
- Fee status for students
- Limited transaction view

### 5. Parent
**Student-Centric View**

**Capabilities**:
- ✅ View own children's information
- ✅ View fee payments for children
- ✅ View transaction history for children
- ✅ View class information

**Dashboard Features**:
- Child selector dropdown
- Fee payment status
- Payment history
- Class and session information

---

## Testing Scenarios

### Scenario 1: Initial Setup (Proprietor)

#### Step 1: Login as Proprietor
1. Navigate to login page
2. Enter proprietor credentials
3. Verify successful login and redirect to dashboard

#### Step 2: Create Section
1. Dashboard → Quick Actions → "Manage Sections"
2. Click "Add Section" button (FAB)
3. Fill in:
   - Section Name: "Primary School"
   - Section Type: "Primary"
   - About Section: "Primary education level"
4. Click "Add Section"
5. **Expected**: Success message, redirect to section list

#### Step 3: Create Academic Session
1. From Sections list → Select "Primary School"
2. Click "Add Session" option
3. Fill in:
   - Session Name: "2024/2025"
   - Start Date: 01/09/2024
   - End Date: 31/07/2025
4. Click "Add Session"
5. **Expected**: Success message, session appears in list

#### Step 4: Create Terms
1. From Session view → "Add Term"
2. Create Term 1:
   - Name: "First Term"
   - Start: 01/09/2024
   - End: 20/12/2024
   - Is Active: Yes
3. Repeat for Second and Third Terms

#### Step 5: Create Classes
1. Navigate to "Manage Classes"
2. Click "Add Class"
3. Fill in:
   - Class Name: "Grade 1"
   - Section: "Primary School"
   - Capacity: 30
4. **Expected**: Class created successfully

#### Step 6: Add Students
1. Navigate to "Manage Students"
2. Click "Add Student" (FAB)
3. Fill in all required fields
4. **Expected**: Student added successfully

---

### Scenario 2: User Management (Proprietor)

#### Create Principal User
1. Navigate to "Users" from sidebar
2. Click "Add User" (FAB)
3. Fill in:
   - Full Name: "John Principal"
   - Email: "principal@school.com"
   - Password: "Password123"
   - Role: "Principal"
   - Assigned Sections: Select "Primary School"
4. Click "Create User"
5. **Expected**: User created, appears in users list

#### Verify Principal Access
1. Logout from proprietor account
2. Login as Principal (principal@school.com)
3. **Verify**:
   - Can only see assigned section (Primary School)
   - Cannot access "All Sections"
   - Cannot manage users
   - Can manage students in assigned section

---

### Scenario 3: Financial Management (Bursar)

#### Create Fee Structure
1. Login as Bursar
2. Navigate to "Manage Fees"
3. Click "Add Fee"
4. Fill in:
   - Fee Name: "Tuition Fee - Grade 1"
   - Amount: 50000
   - Fee Type: "Tuition"
   - Scope: "Class"
   - Select Class: "Grade 1"
5. **Expected**: Fee created and listed

#### Assign Fee to Students
1. From fee list → Click fee → "Assign to Students"
2. Select students or "All students in class"
3. Click "Assign"
4. **Expected**: Fee assigned, visible in student profiles

#### Record Payment
1. Navigate to "Transactions"
2. Click "Add Transaction" (FAB)
3. Fill in:
   - Type: "Credit" (Income)
   - Category: "Tuition Payment"
   - Amount: 50000
   - Payment Method: "Bank Transfer"
   - Student: Select student
4. Click "Add Transaction"
5. **Expected**: Transaction recorded, balance updated

---

### Scenario 4: Profile Management (All Users)

#### Access Profile
1. Login as any user
2. Click profile icon (account_circle) in top-right AppBar
3. **Expected**: Navigate to profile page

#### View Profile Information
1. Verify displayed information:
   - Full Name
   - Email
   - Role
   - Assigned Sections (if applicable)
   - School Information

#### Edit Profile (if available)
1. Click "Edit Profile" button
2. Update information
3. Save changes
4. **Expected**: Profile updated successfully

#### Logout
1. From profile page or AppBar
2. Click logout icon/button
3. **Expected**: Redirected to login page

---

### Scenario 5: Dashboard Navigation

#### Test All Quick Actions
1. **Proprietor Dashboard**:
   - ✓ Manage Sections
   - ✓ Manage Users
   - ✓ Manage Classes
   - ✓ Manage Students
   - ✓ Record Transaction
   - ✓ View Reports

2. **Bursar Dashboard**:
   - ✓ Record Income
   - ✓ Record Expense
   - ✓ Manage Fees
   - ✓ View Reports

3. **Principal Dashboard**:
   - ✓ Manage Students
   - ✓ Manage Classes
   - ✓ View Fees

#### Test Filter Selections
1. Select different **Sections** (if multiple exist)
2. Select different **Sessions**
3. Select different **Terms**
4. Select different **Classes**
5. **Expected**: Dashboard stats update accordingly

---

## Backend API Testing

### Using Postman/Thunder Client

#### 1. Authentication

**Register User**
```http
POST http://localhost:8000/api/register
Content-Type: application/json

{
  "email": "test@school.com",
  "password": "Password123",
  "password_confirmation": "Password123",
  "full_name": "Test User",
  "school_id": 1,
  "role": "principal"
}
```

**Login**
```http
POST http://localhost:8000/api/login
Content-Type: application/json

{
  "email": "test@school.com",
  "password": "Password123"
}
```

**Response**: Save the `token` for subsequent requests

#### 2. Protected Routes

**Get Sections** (Requires Authentication)
```http
GET http://localhost:8000/api/sections?is_active=1
Authorization: Bearer YOUR_TOKEN_HERE
```

**Create Section**
```http
POST http://localhost:8000/api/sections
Authorization: Bearer YOUR_TOKEN_HERE
Content-Type: application/json

{
  "section_name": "Secondary School",
  "type": "Secondary",
  "about_section": "Secondary education level",
  "is_active": true
}
```

#### 3. Dashboard Stats
```http
GET http://localhost:8000/api/transactions/dashboard-stats?section_id=1&session_id=1
Authorization: Bearer YOUR_TOKEN_HERE
```

---

## Known Issues & Workarounds

### Issue 1: Deprecated Code Warnings
**Status**: Non-blocking  
**Impact**: ~220 warnings in `flutter analyze`  
**Resolution**: Planned for future maintenance  
**Workaround**: Warnings don't affect functionality

### Issue 2: Missing Profile Screen Route
**Symptom**: Navigation to `/profile` may fail  
**Workaround**: Ensure route is defined in `main.dart`:
```dart
routes: {
  '/profile': (context) => const ProfileScreen(),
}
```

### Issue 3: CORS Issues (Development)
**Symptom**: Backend requests blocked  
**Solution**: Ensure Laravel backend has proper CORS configuration in `config/cors.php`

### Issue 4: Database Connection
**Symptom**: "Connection refused" errors  
**Check**:
1. MySQL/MariaDB is running
2. `.env` file has correct credentials
3. Database exists
4. Migrations are run

---

## Testing Checklist

### Pre-Testing
- [ ] Backend server running
- [ ] Database migrations completed
- [ ] Flutter dependencies installed
- [ ] API URL configured correctly

### Authentication
- [ ] User registration works
- [ ] Login with valid credentials
- [ ] Login with invalid credentials shows error
- [ ] Logout redirects to login
- [ ] Profile button accessible from dashboard

### Proprietor Tests
- [ ] Can create sections
- [ ] Can create sessions
- [ ] Can create terms
- [ ] Can create classes
- [ ] Can add students
- [ ] Can manage users
- [ ] Can view all sections
- [ ] Can record transactions
- [ ] Can manage fees

### Principal Tests
- [ ] Sees only assigned sections
- [ ] Can manage students in assigned sections
- [ ] Can create classes in assigned sections
- [ ] Cannot access user management
- [ ] Cannot see unassigned sections

### Bursar Tests
- [ ] Can record income transactions
- [ ] Can record expense transactions
- [ ] Can create fee structures
- [ ] Can assign fees to students/classes
- [ ] Can view financial reports

### UI/UX Tests
- [ ] Profile button visible in AppBar
- [ ] Logout button visible in AppBar
- [ ] Tooltips show on icon hover
- [ ] Dashboard loads without errors
- [ ] Filter dropdowns work
- [ ] Quick actions navigate correctly
- [ ] Cards display proper data

### Data Validation
- [ ] Empty form submissions show errors
- [ ] Invalid email format rejected
- [ ] Password requirements enforced
- [ ] Date validations work (end > start)
- [ ] Numeric fields accept only numbers

---

## Support & Troubleshooting

### Common Errors

**"Column not found" SQL Error**
- **Cause**: Missing database migration
- **Fix**: Run `php artisan migrate`

**"Unauthenticated" Error**
- **Cause**: Missing or invalid token
- **Fix**: Re-login to get new token

**"Section not found" Error**
- **Cause**: No sections created yet
- **Fix**: Create at least one section as Proprietor

### Getting Help
1. Check browser console for errors
2. Check backend logs: `storage/logs/laravel.log`
3. Run `flutter analyze` for frontend issues
4. Verify database tables exist

---

## Performance Tips

1. **Pagination**: Use limit parameters in API calls
2. **Caching**: Backend uses query caching where applicable
3. **Lazy Loading**: Dashboard loads data progressively
4. **Debouncing**: Search inputs have debounce delays

---

## Security Notes

### Best Practices
- ✅ Never commit `.env` files
- ✅ Use strong passwords for production
- ✅ Rotate tokens regularly
- ✅ Validate all inputs server-side
- ✅ Use HTTPS in production

### Default Credentials (Development Only)
**Change these in production!**
- Admin: Check database for initial user

---

## Next Steps

After successful testing:
1. [ ] Deploy backend to production server
2. [ ] Build Flutter web for production (`flutter build web`)
3. [ ] Configure production environment variables
4. [ ] Set up SSL/HTTPS
5. [ ] Configure backup strategy
6. [ ] Set up monitoring and logging

---

**Happy Testing! 🚀**
