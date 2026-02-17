# School Management App - Laravel Backend

This is the Laravel backend for the School Management App, migrated from Firebase to provide better control, cost optimization, and advanced query capabilities.

## 📋 Requirements

- PHP 8.1 or higher
- Composer
- MySQL 8.0 or higher
- Node.js & NPM (for asset compilation)

## 🚀 Quick Start

### 1. Install Dependencies

```bash
composer install
npm install
```

### 2. Environment Configuration

Copy the `.env.example` file to `.env`:

```bash
cp .env.example .env
```

Update the following database configuration in `.env`:

```env
DB_CONNECTION=mysql
DB_HOST=127.0.0.1
DB_PORT=3306
DB_DATABASE=school_management
DB_USERNAME=your_username
DB_PASSWORD=your_password
```

### 3. Generate Application Key

```bash
php artisan key:generate
```

### 4. Create Database

Create a MySQL database named `school_management`:

```sql
CREATE DATABASE school_management CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
```

### 5. Run Migrations

```bash
php artisan migrate
```

### 6. Seed Demo Data (Optional)

```bash
php artisan db:seed
```

This will create:
- A demo school
- Proprietor account: `proprietor@demoschool.com` / `password`
- Principal account: `principal@demoschool.com` / `password`
- Bursar account: `bursar@demoschool.com` / `password`

### 7. Start Development Server

```bash
php artisan serve
```

The API will be available at `http://localhost:8000`

## 📁 Database Schema

The application uses the following tables:

1. **schools** - School information
2. **users** - User accounts with role-based access
3. **sections** - School sections/branches
4. **user_section** - User-section assignments (pivot table)
5. **academic_sessions** - Academic years/sessions
6. **terms** - Academic terms within sessions
7. **classes** - Class/grade levels
8. **students** - Student records
9. **fees** - Fee structures
10. **transactions** - Financial transactions (income/expense)

## 🔐 Authentication

The application will use JWT (JSON Web Tokens) for authentication.

### Installing JWT Package

```bash
composer require tymon/jwt-auth
php artisan vendor:publish --provider="Tymon\JWTAuth\Providers\LaravelServiceProvider"
php artisan jwt:secret
```

## 📡 API Endpoints (To Be Implemented)

### Authentication
- `POST /api/auth/register` - Register new user
- `POST /api/auth/login` - Login
- `POST /api/auth/logout` - Logout
- `GET /api/auth/me` - Get current user

### Schools
- `GET /api/schools` - List schools
- `POST /api/schools` - Create school
- `GET /api/schools/{id}` - Get school
- `PUT /api/schools/{id}` - Update school
- `DELETE /api/schools/{id}` - Delete school

### Sections
- `GET /api/schools/{schoolId}/sections` - List sections
- `POST /api/schools/{schoolId}/sections` - Create section
- `GET /api/schools/{schoolId}/sections/{id}` - Get section
- `PUT /api/schools/{schoolId}/sections/{id}` - Update section
- `DELETE /api/schools/{schoolId}/sections/{id}` - Delete section

### Users
- `GET /api/schools/{schoolId}/users` - List users
- `POST /api/schools/{schoolId}/users` - Create user
- `GET /api/schools/{schoolId}/users/{id}` - Get user
- `PUT /api/schools/{schoolId}/users/{id}` - Update user
- `DELETE /api/schools/{schoolId}/users/{id}` - Delete user

### Students
- `GET /api/schools/{schoolId}/students` - List students
- `POST /api/schools/{schoolId}/students` - Create student
- `GET /api/schools/{schoolId}/students/{id}` - Get student
- `PUT /api/schools/{schoolId}/students/{id}` - Update student
- `DELETE /api/schools/{schoolId}/students/{id}` - Delete student

### Transactions
- `GET /api/schools/{schoolId}/transactions` - List transactions
- `POST /api/schools/{schoolId}/transactions` - Create transaction
- `GET /api/schools/{schoolId}/transactions/{id}` - Get transaction
- `GET /api/schools/{schoolId}/transactions/dashboard-stats` - Dashboard statistics
- `GET /api/schools/{schoolId}/transactions/report` - Transaction report

## 🧪 Testing

Run tests with:

```bash
php artisan test
```

## 📝 Models

All Eloquent models are located in `app/Models/`:

- `School.php` - School model
- `User.php` - User model with authentication
- `Section.php` - Section model
- `AcademicSession.php` - Academic session model
- `Term.php` - Term model
- `ClassModel.php` - Class model (named to avoid PHP keyword conflict)
- `Student.php` - Student model
- `Fee.php` - Fee model
- `Transaction.php` - Transaction model

## 🔄 Migration from Firebase

### Data Export

Use the Node.js script in the migration plan to export Firestore data:

```javascript
// See MIGRATION_PLAN_LARAVEL.md for export script
```

### Data Import

Create an artisan command to import the exported JSON data:

```bash
php artisan make:command ImportFirestoreData
```

## 🛠️ Development

### Code Style

Follow PSR-12 coding standards:

```bash
composer require --dev laravel/pint
./vendor/bin/pint
```

### Database Migrations

Create new migrations:

```bash
php artisan make:migration create_table_name
```

### Models

Create new models:

```bash
php artisan make:model ModelName -m
```

### Controllers

Create new controllers:

```bash
php artisan make:controller ControllerName --api
```

## 📊 Performance Optimization

### Query Optimization

Use eager loading to avoid N+1 queries:

```php
$students = Student::with(['school', 'section', 'classModel'])->get();
```

### Caching

Configure Redis for caching in `.env`:

```env
CACHE_DRIVER=redis
SESSION_DRIVER=redis
QUEUE_CONNECTION=redis
```

### Database Indexing

All foreign keys and frequently queried columns are indexed in migrations.

## 🔒 Security

### CORS Configuration

Update `config/cors.php` to allow requests from your Flutter app:

```php
'paths' => ['api/*'],
'allowed_origins' => ['http://localhost:*'],
```

### Rate Limiting

API rate limiting is configured in `app/Http/Kernel.php`:

```php
'api' => [
    'throttle:60,1', // 60 requests per minute
],
```

## 📦 Deployment

### Production Checklist

- [ ] Set `APP_ENV=production` in `.env`
- [ ] Set `APP_DEBUG=false` in `.env`
- [ ] Configure production database
- [ ] Set up SSL certificate
- [ ] Configure queue workers
- [ ] Set up scheduled tasks (cron)
- [ ] Configure backup system
- [ ] Set up monitoring (e.g., Laravel Telescope)

### Optimization

```bash
php artisan config:cache
php artisan route:cache
php artisan view:cache
composer install --optimize-autoloader --no-dev
```

## 📚 Resources

- [Laravel Documentation](https://laravel.com/docs)
- [JWT Auth Documentation](https://jwt-auth.readthedocs.io/)
- [Migration Plan](../MIGRATION_PLAN_LARAVEL.md)

## 🐛 Troubleshooting

### Common Issues

**Issue**: Migration fails with foreign key constraint error
**Solution**: Ensure migrations run in correct order (check timestamps)

**Issue**: JWT token invalid
**Solution**: Run `php artisan jwt:secret` and clear config cache

**Issue**: CORS errors from Flutter app
**Solution**: Update `config/cors.php` with correct origins

## 📞 Support

For issues or questions, refer to the main project documentation or create an issue in the repository.

---

**Version**: 1.0.0  
**Last Updated**: 2025-12-02
