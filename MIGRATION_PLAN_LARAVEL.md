# Migration Plan: Firebase to Laravel + MySQL

## Executive Summary

This document outlines the complete migration strategy for transitioning the School Management App from a Firebase backend to a Laravel + MySQL architecture, while maintaining the Flutter frontend.

**Current Stack:**
- Frontend: Flutter
- Backend: Firebase (Auth, Firestore, Storage)
- Database: Cloud Firestore (NoSQL)

**Target Stack:**
- Frontend: Flutter (minimal changes)
- Backend: Laravel 10+ (PHP 8.1+)
- Database: MySQL 8.0+
- API: RESTful API with JWT authentication
- Storage: Laravel Storage (local/S3)

---

## Table of Contents

1. [Migration Objectives](#migration-objectives)
2. [Architecture Comparison](#architecture-comparison)
3. [Database Schema Design](#database-schema-design)
4. [API Design](#api-design)
5. [Authentication Strategy](#authentication-strategy)
6. [Implementation Phases](#implementation-phases)
7. [Data Migration Strategy](#data-migration-strategy)
8. [Testing Strategy](#testing-strategy)
9. [Deployment Plan](#deployment-plan)
10. [Risk Assessment](#risk-assessment)

---

## Migration Objectives

### Why Migrate?

1. **Cost Optimization**: Reduce dependency on Firebase pricing
2. **Data Control**: Full ownership of data and infrastructure
3. **Advanced Queries**: Leverage SQL for complex financial reports
4. **Customization**: Greater flexibility in business logic
5. **Compliance**: Easier to meet local data residency requirements
6. **Scalability**: Better control over scaling strategy

### Success Criteria

- ✅ Zero data loss during migration
- ✅ Minimal downtime (< 2 hours)
- ✅ All existing features working
- ✅ Improved query performance for reports
- ✅ Successful user authentication migration

---

## Architecture Comparison

### Current Architecture (Firebase)

```
┌─────────────────┐
│  Flutter App    │
└────────┬────────┘
         │
         ├──────────────┐
         │              │
    ┌────▼─────┐   ┌───▼──────┐
    │Firebase  │   │Firestore │
    │  Auth    │   │ Database │
    └──────────┘   └──────────┘
```

### Target Architecture (Laravel)

```
┌─────────────────┐
│  Flutter App    │
└────────┬────────┘
         │ REST API
    ┌────▼─────────────┐
    │  Laravel Backend │
    │  - Controllers   │
    │  - Middleware    │
    │  - Services      │
    └────┬─────────────┘
         │
    ┌────▼─────┐
    │  MySQL   │
    │ Database │
    └──────────┘
```

---

## Database Schema Design

### Firestore Collections → MySQL Tables

#### 1. **Users Collection** → `users` table

**Firestore:**
```json
{
  "uid": "string",
  "email": "string",
  "fullName": "string",
  "role": "string",
  "schoolId": "string",
  "assignedSections": ["array"],
  "createdAt": "timestamp"
}
```

**MySQL:**
```sql
CREATE TABLE users (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    firebase_uid VARCHAR(255) UNIQUE, -- For migration tracking
    email VARCHAR(255) UNIQUE NOT NULL,
    password VARCHAR(255) NOT NULL,
    full_name VARCHAR(255) NOT NULL,
    role ENUM('proprietor', 'principal', 'bursar', 'teacher', 'parent') NOT NULL,
    school_id BIGINT UNSIGNED NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    email_verified_at TIMESTAMP NULL,
    remember_token VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    INDEX idx_school_id (school_id),
    INDEX idx_role (role),
    INDEX idx_email (email),
    
    FOREIGN KEY (school_id) REFERENCES schools(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

#### 2. **Schools Collection** → `schools` table

```sql
CREATE TABLE schools (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    address TEXT,
    phone VARCHAR(50),
    email VARCHAR(255),
    logo_url VARCHAR(500),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    INDEX idx_name (name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

#### 3. **Sections Collection** → `sections` table

```sql
CREATE TABLE sections (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    school_id BIGINT UNSIGNED NOT NULL,
    section_name VARCHAR(255) NOT NULL,
    description TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    INDEX idx_school_id (school_id),
    
    FOREIGN KEY (school_id) REFERENCES schools(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

#### 4. **User-Section Assignment** → `user_section` table

```sql
CREATE TABLE user_section (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT UNSIGNED NOT NULL,
    section_id BIGINT UNSIGNED NOT NULL,
    assigned_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    UNIQUE KEY unique_user_section (user_id, section_id),
    
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (section_id) REFERENCES sections(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

#### 5. **Academic Sessions** → `academic_sessions` table

```sql
CREATE TABLE academic_sessions (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    school_id BIGINT UNSIGNED NOT NULL,
    section_id BIGINT UNSIGNED NOT NULL,
    session_name VARCHAR(255) NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    INDEX idx_school_section (school_id, section_id),
    INDEX idx_active (is_active),
    
    FOREIGN KEY (school_id) REFERENCES schools(id) ON DELETE CASCADE,
    FOREIGN KEY (section_id) REFERENCES sections(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

#### 6. **Terms** → `terms` table

```sql
CREATE TABLE terms (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    school_id BIGINT UNSIGNED NOT NULL,
    section_id BIGINT UNSIGNED NOT NULL,
    session_id BIGINT UNSIGNED NOT NULL,
    term_name VARCHAR(255) NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    INDEX idx_session (session_id),
    
    FOREIGN KEY (school_id) REFERENCES schools(id) ON DELETE CASCADE,
    FOREIGN KEY (section_id) REFERENCES sections(id) ON DELETE CASCADE,
    FOREIGN KEY (session_id) REFERENCES academic_sessions(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

#### 7. **Classes** → `classes` table

```sql
CREATE TABLE classes (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    school_id BIGINT UNSIGNED NOT NULL,
    section_id BIGINT UNSIGNED NOT NULL,
    class_name VARCHAR(255) NOT NULL,
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    INDEX idx_section (section_id),
    
    FOREIGN KEY (school_id) REFERENCES schools(id) ON DELETE CASCADE,
    FOREIGN KEY (section_id) REFERENCES sections(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

#### 8. **Students** → `students` table

```sql
CREATE TABLE students (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    school_id BIGINT UNSIGNED NOT NULL,
    section_id BIGINT UNSIGNED NOT NULL,
    class_id BIGINT UNSIGNED NOT NULL,
    student_name VARCHAR(255) NOT NULL,
    admission_number VARCHAR(100) UNIQUE,
    date_of_birth DATE,
    gender ENUM('male', 'female', 'other'),
    address TEXT,
    parent_name VARCHAR(255),
    parent_phone VARCHAR(50),
    parent_email VARCHAR(255),
    photo_url VARCHAR(500),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    INDEX idx_class (class_id),
    INDEX idx_admission (admission_number),
    INDEX idx_parent_phone (parent_phone),
    
    FOREIGN KEY (school_id) REFERENCES schools(id) ON DELETE CASCADE,
    FOREIGN KEY (section_id) REFERENCES sections(id) ON DELETE CASCADE,
    FOREIGN KEY (class_id) REFERENCES classes(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

#### 9. **Fees** → `fees` table

```sql
CREATE TABLE fees (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    school_id BIGINT UNSIGNED NOT NULL,
    section_id BIGINT UNSIGNED NOT NULL,
    session_id BIGINT UNSIGNED NOT NULL,
    term_id BIGINT UNSIGNED NOT NULL,
    class_id BIGINT UNSIGNED,
    fee_name VARCHAR(255) NOT NULL,
    amount DECIMAL(10, 2) NOT NULL,
    fee_scope ENUM('class', 'section', 'school') NOT NULL,
    description TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    INDEX idx_session_term (session_id, term_id),
    INDEX idx_class (class_id),
    
    FOREIGN KEY (school_id) REFERENCES schools(id) ON DELETE CASCADE,
    FOREIGN KEY (section_id) REFERENCES sections(id) ON DELETE CASCADE,
    FOREIGN KEY (session_id) REFERENCES academic_sessions(id) ON DELETE CASCADE,
    FOREIGN KEY (term_id) REFERENCES terms(id) ON DELETE CASCADE,
    FOREIGN KEY (class_id) REFERENCES classes(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

#### 10. **Transactions** → `transactions` table

```sql
CREATE TABLE transactions (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    school_id BIGINT UNSIGNED NOT NULL,
    section_id BIGINT UNSIGNED NOT NULL,
    session_id BIGINT UNSIGNED,
    term_id BIGINT UNSIGNED,
    student_id BIGINT UNSIGNED,
    transaction_type ENUM('income', 'expense') NOT NULL,
    amount DECIMAL(10, 2) NOT NULL,
    payment_method ENUM('cash', 'bank_transfer', 'cheque', 'mobile_money') NOT NULL,
    category VARCHAR(255),
    description TEXT,
    reference_number VARCHAR(100),
    transaction_date DATE NOT NULL,
    recorded_by BIGINT UNSIGNED NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    INDEX idx_school_section (school_id, section_id),
    INDEX idx_student (student_id),
    INDEX idx_date (transaction_date),
    INDEX idx_type (transaction_type),
    INDEX idx_session_term (session_id, term_id),
    
    FOREIGN KEY (school_id) REFERENCES schools(id) ON DELETE CASCADE,
    FOREIGN KEY (section_id) REFERENCES sections(id) ON DELETE CASCADE,
    FOREIGN KEY (session_id) REFERENCES academic_sessions(id) ON DELETE SET NULL,
    FOREIGN KEY (term_id) REFERENCES terms(id) ON DELETE SET NULL,
    FOREIGN KEY (student_id) REFERENCES students(id) ON DELETE SET NULL,
    FOREIGN KEY (recorded_by) REFERENCES users(id) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

---

## API Design

### Authentication Endpoints

```
POST   /api/auth/register          - Register new user
POST   /api/auth/login             - Login user
POST   /api/auth/logout            - Logout user
POST   /api/auth/refresh           - Refresh JWT token
GET    /api/auth/me                - Get current user
POST   /api/auth/forgot-password   - Request password reset
POST   /api/auth/reset-password    - Reset password
```

### Schools Endpoints

```
GET    /api/schools                - List all schools (admin only)
POST   /api/schools                - Create school
GET    /api/schools/{id}           - Get school details
PUT    /api/schools/{id}           - Update school
DELETE /api/schools/{id}           - Delete school
```

### Sections Endpoints

```
GET    /api/schools/{schoolId}/sections          - List sections
POST   /api/schools/{schoolId}/sections          - Create section
GET    /api/schools/{schoolId}/sections/{id}     - Get section
PUT    /api/schools/{schoolId}/sections/{id}     - Update section
DELETE /api/schools/{schoolId}/sections/{id}     - Delete section
```

### Users Endpoints

```
GET    /api/schools/{schoolId}/users             - List users
POST   /api/schools/{schoolId}/users             - Create user
GET    /api/schools/{schoolId}/users/{id}        - Get user
PUT    /api/schools/{schoolId}/users/{id}        - Update user
DELETE /api/schools/{schoolId}/users/{id}        - Delete user
POST   /api/schools/{schoolId}/users/{id}/assign-sections  - Assign sections
```

### Academic Sessions Endpoints

```
GET    /api/schools/{schoolId}/sessions                           - List sessions
POST   /api/schools/{schoolId}/sections/{sectionId}/sessions      - Create session
GET    /api/schools/{schoolId}/sessions/{id}                      - Get session
PUT    /api/schools/{schoolId}/sessions/{id}                      - Update session
DELETE /api/schools/{schoolId}/sessions/{id}                      - Delete session
```

### Terms Endpoints

```
GET    /api/schools/{schoolId}/terms                                     - List terms
POST   /api/schools/{schoolId}/sessions/{sessionId}/terms                - Create term
GET    /api/schools/{schoolId}/terms/{id}                                - Get term
PUT    /api/schools/{schoolId}/terms/{id}                                - Update term
DELETE /api/schools/{schoolId}/terms/{id}                                - Delete term
```

### Classes Endpoints

```
GET    /api/schools/{schoolId}/classes                        - List classes
POST   /api/schools/{schoolId}/sections/{sectionId}/classes   - Create class
GET    /api/schools/{schoolId}/classes/{id}                   - Get class
PUT    /api/schools/{schoolId}/classes/{id}                   - Update class
DELETE /api/schools/{schoolId}/classes/{id}                   - Delete class
```

### Students Endpoints

```
GET    /api/schools/{schoolId}/students                       - List students
POST   /api/schools/{schoolId}/classes/{classId}/students     - Create student
GET    /api/schools/{schoolId}/students/{id}                  - Get student
PUT    /api/schools/{schoolId}/students/{id}                  - Update student
DELETE /api/schools/{schoolId}/students/{id}                  - Delete student
GET    /api/schools/{schoolId}/students/{id}/transactions     - Get student transactions
POST   /api/schools/{schoolId}/students/import                - Bulk import students
```

### Fees Endpoints

```
GET    /api/schools/{schoolId}/fees                    - List fees
POST   /api/schools/{schoolId}/fees                    - Create fee
GET    /api/schools/{schoolId}/fees/{id}               - Get fee
PUT    /api/schools/{schoolId}/fees/{id}               - Update fee
DELETE /api/schools/{schoolId}/fees/{id}               - Delete fee
POST   /api/schools/{schoolId}/fees/assign-students    - Assign fees to students
```

### Transactions Endpoints

```
GET    /api/schools/{schoolId}/transactions                   - List transactions
POST   /api/schools/{schoolId}/transactions                   - Create transaction
GET    /api/schools/{schoolId}/transactions/{id}              - Get transaction
PUT    /api/schools/{schoolId}/transactions/{id}              - Update transaction
DELETE /api/schools/{schoolId}/transactions/{id}              - Delete transaction
GET    /api/schools/{schoolId}/transactions/dashboard-stats   - Get dashboard statistics
GET    /api/schools/{schoolId}/transactions/report            - Get transaction report
```

---

## Authentication Strategy

### JWT Implementation

**Laravel Packages:**
- `tymon/jwt-auth` - JWT authentication

**Token Structure:**
```json
{
  "sub": "user_id",
  "email": "user@example.com",
  "role": "principal",
  "school_id": "123",
  "exp": 1234567890
}
```

**Middleware Stack:**
1. `auth:api` - Verify JWT token
2. `role:proprietor,principal` - Role-based access
3. `school.access` - School-level permissions

### Migration from Firebase Auth

**Strategy:**
1. Export user emails from Firebase
2. Create Laravel users with temporary passwords
3. Send password reset emails to all users
4. Users set new passwords on first login

**Alternate Strategy (Seamless):**
1. Keep Firebase Auth temporarily
2. Implement dual authentication in Laravel
3. Gradually migrate users on login
4. Deprecate Firebase after 100% migration

---

## Implementation Phases

### Phase 1: Backend Setup (Week 1-2)

**Tasks:**
- ✅ Set up Laravel project
- ✅ Configure MySQL database
- ✅ Create all database migrations
- ✅ Set up JWT authentication
- ✅ Implement user seeding
- ✅ Configure CORS for Flutter app

**Deliverables:**
- Laravel project structure
- Database schema implemented
- Authentication working

### Phase 2: Core API Development (Week 3-4)

**Tasks:**
- ✅ Implement authentication endpoints
- ✅ Implement schools/sections CRUD
- ✅ Implement users management
- ✅ Implement academic sessions/terms
- ✅ Write API tests

**Deliverables:**
- Core APIs functional
- Postman collection
- API documentation

### Phase 3: Financial Module (Week 5-6)

**Tasks:**
- ✅ Implement classes/students APIs
- ✅ Implement fees management
- ✅ Implement transactions APIs
- ✅ Implement dashboard statistics
- ✅ Implement reporting endpoints

**Deliverables:**
- All financial APIs working
- Performance optimized queries
- Reports generation

### Phase 4: Data Migration (Week 7)

**Tasks:**
- ✅ Export data from Firestore
- ✅ Transform data to MySQL format
- ✅ Import data to MySQL
- ✅ Verify data integrity
- ✅ Create migration scripts

**Deliverables:**
- Migration scripts
- Data validation report
- Rollback procedures

### Phase 5: Flutter Integration (Week 8-9)

**Tasks:**
- ✅ Create `ApiService` class
- ✅ Replace Firebase calls with API calls
- ✅ Update authentication flow
- ✅ Update all data fetching
- ✅ Handle API errors

**Deliverables:**
- Updated Flutter app
- All features working with API
- Error handling implemented

### Phase 6: Testing & QA (Week 10)

**Tasks:**
- ✅ Integration testing
- ✅ Load testing
- ✅ Security testing
- ✅ User acceptance testing
- ✅ Bug fixes

**Deliverables:**
- Test reports
- Bug fix changelog
- Performance benchmarks

### Phase 7: Deployment (Week 11)

**Tasks:**
- ✅ Deploy Laravel to production
- ✅ Set up MySQL replication
- ✅ Configure CI/CD
- ✅ Migrate production data
- ✅ Monitor and optimize

**Deliverables:**
- Production environment live
- Monitoring dashboards
- Deployment documentation

---

## Data Migration Strategy

### Step 1: Export from Firestore

```javascript
// Node.js script to export Firestore data
const admin = require('firebase-admin');
const fs = require('fs');

admin.initializeApp();
const db = admin.firestore();

async function exportCollection(collectionName) {
  const snapshot = await db.collection(collectionName).get();
  const data = snapshot.docs.map(doc => ({
    id: doc.id,
    ...doc.data()
  }));
  fs.writeFileSync(`${collectionName}.json`, JSON.stringify(data, null, 2));
}

// Export all collections
exportCollection('schools');
exportCollection('users');
exportCollection('sections');
// ... etc
```

### Step 2: Transform Data

```php
// Laravel artisan command
php artisan migrate:firestore-to-mysql --collection=users
```

### Step 3: Validate Migration

```php
// Validation script
- Compare record counts
- Verify relationships
- Check data integrity
- Validate financial calculations
```

---

## Testing Strategy

### Unit Tests
- Model validations
- Business logic
- Calculations (fees, transactions)

### Integration Tests
- API endpoint tests
- Authentication flow
- Database transactions

### Performance Tests
- Load testing (100+ concurrent users)
- Query optimization
- API response times

### Security Tests
- SQL injection prevention
- XSS prevention
- CSRF protection
- JWT token validation

---

## Deployment Plan

### Server Requirements

**Production Server:**
- Ubuntu 22.04 LTS
- PHP 8.1+
- MySQL 8.0+
- Nginx
- Redis (for caching)
- SSL certificate

**Recommended Hosting:**
- DigitalOcean Droplet (4GB RAM, 2 vCPUs)
- AWS EC2 (t3.medium)
- Linode

### Deployment Steps

1. **Provision Server**
2. **Install Dependencies**
3. **Configure Nginx**
4. **Set up MySQL**
5. **Deploy Laravel**
6. **Run Migrations**
7. **Import Data**
8. **Configure Queue Workers**
9. **Set up Monitoring**
10. **Update Flutter App**

---

## Risk Assessment

### High Risks

| Risk | Impact | Mitigation |
|------|--------|------------|
| Data Loss | Critical | Multiple backups, dry runs |
| Extended Downtime | High | Parallel run, gradual migration |
| Authentication Issues | High | Dual auth during transition |
| Performance Degradation | Medium | Load testing, optimization |

### Medium Risks

| Risk | Impact | Mitigation |
|------|--------|------------|
| API Breaking Changes | Medium | Versioned API, backward compatibility |
| User Resistance | Medium | Training, documentation |
| Cost Overrun | Medium | Phased approach, clear timeline |

---

## Post-Migration Checklist

- [ ] All features working
- [ ] Performance acceptable
- [ ] Security audit passed
- [ ] Backup systems in place
- [ ] Monitoring configured
- [ ] Documentation updated
- [ ] Users trained
- [ ] Firebase services disabled
- [ ] Cost savings verified

---

## Rollback Plan

If migration fails:

1. **Immediate**: Revert Flutter app to Firebase
2. **Database**: Restore from Firebase backup
3. **Communication**: Notify all users
4. **Analysis**: Document issues
5. **Planning**: Address blockers before retry

---

## Budget Estimate

| Item | Cost (USD) |
|------|------------|
| Server (1 year) | $240 |
| SSL Certificate | $0 (Let's Encrypt) |
| Development Time (11 weeks) | Custom |
| Testing Tools | $100 |
| Total | $340 + Dev Time |

**ROI Timeline**: 6-12 months (Firebase cost savings)

---

## Support & Maintenance

**Post-Migration:**
- Weekly backups
- Security updates
- Performance monitoring
- User support
- Feature enhancements

---

**Document Version**: 1.0  
**Last Updated**: 2025-12-02  
**Owner**: Development Team  
**Status**: Ready for Review
