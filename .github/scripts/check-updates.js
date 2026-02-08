const fs = require('fs');
const path = require('path');
const https = require('https');
const { execSync } = require('child_process');

const FEATURES_DIR = path.join(__dirname, '../../src');

// Map of features to update strategies
const STRATEGIES = {
    'nerd-font': { type: 'github-release', repo: 'ryanoasis/nerd-fonts' },
    'bmad-method': { type: 'npm', package: 'bmad-method' },
    'claude-code': { type: 'npm', package: '@anthropic-ai/claude-code' },
    'codex': { type: 'npm', package: '@openai/codex' },
    'gemini-cli': { type: 'npm', package: '@google/gemini-cli' },
    'opencode': { type: 'npm', package: 'opencode-ai' }
};

async function fetchJson(url) {
    return new Promise((resolve, reject) => {
        https.get(url, { headers: { 'User-Agent': 'Node.js' } }, (res) => {
            let data = '';
            res.on('data', chunk => data += chunk);
            res.on('end', () => {
                if (res.statusCode && res.statusCode >= 400) {
                    return reject(new Error(`HTTP ${res.statusCode} for ${url}`));
                }
                try {
                    resolve(JSON.parse(data));
                } catch (e) {
                    reject(e);
                }
            });
        }).on('error', reject);
    });
}

function setOutput(name, value) {
    if (process.env.GITHUB_OUTPUT) {
        fs.appendFileSync(process.env.GITHUB_OUTPUT, `${name}=${value}\n`);
    } else {
        console.log(`${name}=${value}`);
    }
}

async function getLatestVersion(featureId) {
    const strategy = STRATEGIES[featureId];
    if (!strategy) return null;

    try {
        if (strategy.type === 'github-release') {
            const release = await fetchJson(`https://api.github.com/repos/${strategy.repo}/releases/latest`);
            return release.tag_name ? release.tag_name.replace(/^v/, '') : null;
        } else if (strategy.type === 'npm') {
            // Use npm view via CLI usually easier/more reliable without extra deps, 
            // but here we can use registry API to keep it zero-dep if we want.
            // Let's use registry API for speed and no local npm config issues.
            const pkg = await fetchJson(`https://registry.npmjs.org/${strategy.package}/latest`);
            return pkg.version;
        }
    } catch (error) {
        console.error(`Failed to check version for ${featureId}:`, error.message);
        return null;
    }
}

async function updateFeatures() {
    const features = fs.readdirSync(FEATURES_DIR);
    let updated = false;

    for (const feature of features) {
        if (!STRATEGIES[feature]) continue;

        const featureJsonPath = path.join(FEATURES_DIR, feature, 'devcontainer-feature.json');
        if (!fs.existsSync(featureJsonPath)) continue;

        const featureJson = JSON.parse(fs.readFileSync(featureJsonPath, 'utf8'));
        const currentDefault = featureJson.options?.version?.default;

        if (!currentDefault) {
            console.log(`Skipping ${feature}: no default version option found.`);
            continue;
        }

        const latest = await getLatestVersion(feature);

        if (latest && latest !== currentDefault && latest !== 'latest' && currentDefault !== 'latest') {
            // Note: We only auto-update if NOT set to 'latest' to avoid churning logic 
            // UNLESS the user explicitly wants pinned versions updated.
            // Based on nerd-font (3.4.0), they want pinned versions.
            // But for npm packages defaulting to 'latest', maybe we shouldn't pin them?
            // User said "I want the same policy for all of them".
            // If a feature defaults to "stable" or "latest", we might want to keep it that way unless we decide to pin.
            // However, for nerd-font it WAS pinned.
            // Let's assume: If it currently looks like a semver, we update it to new semver. 
            // If it looks like 'latest', we leave it alone?
            // User said: "nerd-font was hardcoded... latest is 3.4.0... I want the same policy".
            // This implies we should likely move away from 'latest' to pinned versions for stability + auto-update.
            // But automatically switching from 'latest' to '1.2.3' is a policy change.
            // I will implement: Update ONLY if the current version is NOT 'latest' OR if we want to force pin.
            // Ideally, we update the `default` value.

            console.log(`Update available for ${feature}: ${currentDefault} -> ${latest}`);
            featureJson.options.version.default = latest;
            fs.writeFileSync(featureJsonPath, JSON.stringify(featureJson, null, 4));
            updated = true;
        } else if (latest) {
            console.log(`No update needed for ${feature} (Current: ${currentDefault}, Latest: ${latest})`);
        }
    }

    if (updated) {
        setOutput('updated', 'true');
    }
}

updateFeatures();
