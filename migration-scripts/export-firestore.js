const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');

// Initialize Firebase Admin SDK
// Replace with your Firebase service account key path
const serviceAccount = require('./firebase-service-account.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

// Output directory for exported data
const outputDir = './firestore-export';

// Create output directory if it doesn't exist
if (!fs.existsSync(outputDir)) {
  fs.mkdirSync(outputDir, { recursive: true });
}

/**
 * Export a Firestore collection to JSON
 */
async function exportCollection(collectionName) {
  console.log(`Exporting ${collectionName}...`);
  
  try {
    const snapshot = await db.collection(collectionName).get();
    const data = [];
    
    snapshot.forEach(doc => {
      const docData = doc.data();
      
      // Convert Firestore Timestamps to ISO strings
      Object.keys(docData).forEach(key => {
        if (docData[key] && typeof docData[key].toDate === 'function') {
          docData[key] = docData[key].toDate().toISOString();
        }
      });
      
      data.push({
        id: doc.id,
        ...docData
      });
    });
    
    const outputPath = path.join(outputDir, `${collectionName}.json`);
    fs.writeFileSync(outputPath, JSON.stringify(data, null, 2));
    
    console.log(`✅ Exported ${data.length} documents from ${collectionName}`);
    return data.length;
  } catch (error) {
    console.error(`❌ Error exporting ${collectionName}:`, error);
    return 0;
  }
}

/**
 * Export all collections
 */
async function exportAllCollections() {
  console.log('🚀 Starting Firestore export...\n');
  
  const collections = [
    'schools',
    'users',
    'sections',
    'academicSessions',
    'terms',
    'classes',
    'students',
    'fees',
    'transactions'
  ];
  
  const stats = {};
  
  for (const collection of collections) {
    stats[collection] = await exportCollection(collection);
  }
  
  // Export summary
  const summary = {
    exportDate: new Date().toISOString(),
    collections: stats,
    totalDocuments: Object.values(stats).reduce((a, b) => a + b, 0)
  };
  
  fs.writeFileSync(
    path.join(outputDir, '_export_summary.json'),
    JSON.stringify(summary, null, 2)
  );
  
  console.log('\n📊 Export Summary:');
  console.log('─'.repeat(40));
  Object.entries(stats).forEach(([collection, count]) => {
    console.log(`${collection.padEnd(20)} ${count} documents`);
  });
  console.log('─'.repeat(40));
  console.log(`Total: ${summary.totalDocuments} documents`);
  console.log(`\n✅ Export complete! Files saved to: ${outputDir}`);
}

// Run export
exportAllCollections()
  .then(() => {
    console.log('\n🎉 Export finished successfully!');
    process.exit(0);
  })
  .catch(error => {
    console.error('\n❌ Export failed:', error);
    process.exit(1);
  });
