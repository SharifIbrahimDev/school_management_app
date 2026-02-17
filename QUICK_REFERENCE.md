# 🚀 Quick Reference - Laravel Backend

## One-Line Commands

### Setup
```bash
.\setup-backend.bat                    # Run automated setup
```

### Development
```bash
cd backend && php artisan serve        # Start dev server (http://localhost:8000)
php artisan migrate                    # Run migrations
php artisan migrate:fresh --seed       # Reset DB with demo data
php artisan db:seed                    # Seed demo data only
```

### Database
```bash
php artisan migrate:status             # Check migration status
php artisan migrate:rollback           # Rollback last migration
php artisan db:show                    # Show database info
```

### Code Generation
```bash
php artisan make:controller NameController --api    # Create API controller
php artisan make:model Name -m                      # Create model + migration
php artisan make:seeder NameSeeder                  # Create seeder
php artisan make:request NameRequest                # Create form request
```

### Testing
```bash
php artisan test                       # Run all tests
php artisan test --filter=TestName     # Run specific test
```

### Optimization
```bash
php artisan config:cache               # Cache config
php artisan route:cache                # Cache routes
php artisan view:cache                 # Cache views
php artisan optimize                   # Run all optimizations
php artisan optimize:clear             # Clear all caches
```

## Demo Accounts

| Role | Email | Password |
|------|-------|----------|
| Proprietor | proprietor@demoschool.com | password |
| Principal | principal@demoschool.com | password |
| Bursar | bursar@demoschool.com | password |

## File Locations

| What | Where |
|------|-------|
| Models | `backend/app/Models/` |
| Controllers | `backend/app/Http/Controllers/` |
| Migrations | `backend/database/migrations/` |
| Seeders | `backend/database/seeders/` |
| Routes | `backend/routes/api.php` |
| Config | `backend/.env` |

## Database Schema

```
schools → users (FK: school_id)
       → sections → user_section (pivot)
                 → academic_sessions → terms
                 → classes → students → transactions
                          → fees
```

## Next Phase Checklist

- [ ] Run `.\setup-backend.bat`
- [ ] Verify migrations successful
- [ ] Test demo login credentials
- [ ] Install JWT: `composer require tymon/jwt-auth`
- [ ] Create AuthController
- [ ] Define API routes
- [ ] Test authentication endpoints

## Useful Links

- [Backend README](backend/README.md)
- [Migration Plan](MIGRATION_PLAN_LARAVEL.md)
- [Progress Report](MIGRATION_PROGRESS.md)
- [Laravel Docs](https://laravel.com/docs)
