# Firestore to MySQL Migration Scripts

This directory contains scripts to migrate data from Firebase Firestore to MySQL.

## 📁 Files

- `export-firestore.js` - Node.js script to export Firestore data
- `package.json` - Node.js dependencies
- `firebase-service-account.json` - **YOUR Firebase service account key (not included)**

## 🚀 Quick Start

### 1. Get Firebase Service Account Key

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project
3. Project Settings → Service Accounts
4. Generate New Private Key
5. Save as `firebase-service-account.json` in this directory

### 2. Install Dependencies

```bash
npm install
```

### 3. Run Export

```bash
npm run export
```

### 4. Import to MySQL

```bash
cd ../backend
php artisan import:firestore ../migration-scripts/firestore-export
```

## 📤 Export Output

Data will be exported to `firestore-export/` directory:

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

## 🔒 Security

**IMPORTANT:** Never commit `firebase-service-account.json` to version control!

Add to `.gitignore`:
```
firebase-service-account.json
firestore-export/
```

## 📚 Full Documentation

See `../DATA_MIGRATION_GUIDE.md` for complete migration instructions.

## ⚠️ Notes

- Export script converts Firestore Timestamps to ISO strings
- All data is exported as JSON
- Import command handles ID mapping automatically
- Migration uses database transactions (safe rollback)

## 🆘 Troubleshooting

**Error: Could not load credentials**
- Verify `firebase-service-account.json` exists
- Check file permissions

**Error: Collection not found**
- Verify collection names in Firestore
- Update collection names in `export-firestore.js` if needed

**Error: Permission denied**
- Verify service account has Firestore read permissions
- Check Firebase project settings
