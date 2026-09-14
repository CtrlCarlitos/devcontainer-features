const fs = require('fs');
const path = require('path');

const repositoryRoot = path.resolve(__dirname, '../..');
const source = fs.readFileSync(
    path.join(repositoryRoot, '.github/scripts/check-updates.js'),
    'utf8'
);
const strategies = source.match(/const STRATEGIES = \{([\s\S]*?)\n\};/);

if (!strategies) {
    throw new Error('Could not find Auto-Update strategies');
}

const featureIds = [...strategies[1].matchAll(/^\s*'([^']+)':/gm)].map((match) => match[1]);
const missing = featureIds.filter(
    (featureId) => !fs.existsSync(path.join(repositoryRoot, 'src', featureId))
);

if (missing.length > 0) {
    throw new Error(`Auto-Update strategies without source features: ${missing.join(', ')}`);
}

console.log(`Auto-Update strategies match ${featureIds.length} source features.`);
