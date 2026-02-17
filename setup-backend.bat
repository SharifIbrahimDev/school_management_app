@echo off
REM School Management App - Laravel Backend Setup Script
REM This script helps you set up the Laravel backend

echo ========================================
echo School Management App - Backend Setup
echo ========================================
echo.

REM Check if we're in the right directory
if not exist "backend" (
    echo ERROR: backend directory not found!
    echo Please run this script from the school_management_app directory
    pause
    exit /b 1
)

cd backend

echo Step 1: Installing Composer dependencies...
call composer install
if errorlevel 1 (
    echo ERROR: Composer install failed!
    pause
    exit /b 1
)

echo.
echo Step 2: Copying .env file...
if not exist ".env" (
    copy .env.example .env
    echo .env file created
) else (
    echo .env file already exists
)

echo.
echo Step 3: Generating application key...
call php artisan key:generate

echo.
echo Step 4: Database Configuration
echo ========================================
echo Please update the .env file with your MySQL credentials:
echo.
echo DB_CONNECTION=mysql
echo DB_HOST=127.0.0.1
echo DB_PORT=3306
echo DB_DATABASE=school_management
echo DB_USERNAME=your_username
echo DB_PASSWORD=your_password
echo.
echo Press any key after you've updated the .env file...
pause

echo.
echo Step 5: Creating database (if not exists)...
echo Please create the database manually in MySQL:
echo CREATE DATABASE school_management CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
echo.
echo Press any key after you've created the database...
pause

echo.
echo Step 6: Running migrations...
call php artisan migrate
if errorlevel 1 (
    echo ERROR: Migration failed! Please check your database configuration.
    pause
    exit /b 1
)

echo.
echo Step 7: Seeding demo data...
set /p seed="Do you want to seed demo data? (y/n): "
if /i "%seed%"=="y" (
    call php artisan db:seed
    echo.
    echo Demo accounts created:
    echo - Proprietor: proprietor@demoschool.com / password
    echo - Principal: principal@demoschool.com / password
    echo - Bursar: bursar@demoschool.com / password
)

echo.
echo ========================================
echo Setup Complete!
echo ========================================
echo.
echo To start the development server, run:
echo   php artisan serve
echo.
echo The API will be available at: http://localhost:8000
echo.
echo Next steps:
echo 1. Install JWT authentication: composer require tymon/jwt-auth
echo 2. Create API controllers
echo 3. Define API routes
echo.
pause
