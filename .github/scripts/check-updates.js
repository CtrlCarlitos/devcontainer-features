const fs = require('fs');
const path = require('path');
const https = require('https');
const { execSync } = require('child_process');

const FEATURES_DIR = path.join(__dirname, '../../src');

// Map of features to update strategies
// Note: claude-code uses native installer only (no npm package), so it's excluded from auto-update
const STRATEGIES = {
    'nerd-font': { type: 'github-release', repo: 'ryanoasis/nerd-fonts' },
    'bmad-method': { type: 'npm', package: 'bmad-method', distTags: ['latest', 'beta'] },
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

function compareVersions(v1, v2) {
    // Simple version comparison for formats like "6.0.0-Beta.7"
    // Extract version parts and compare
    const parseVersion = (v) => {
        const match = v.match(/^(\d+)\.(\d+)\.(\d+)(?:-([A-Za-z]+)\.(\d+))?$/);
        if (!match) return { major: 0, minor: 0, patch: 0, prerelease: 'z', prereleaseNum: 0 };
        return {
            major: parseInt(match[1], 10),
            minor: parseInt(match[2], 10),
            patch: parseInt(match[3], 10),
            // If no prerelease processing happened, assume stable 'z' sort order
            prerelease: match[4] || 'stable',
            prereleaseNum: match[5] ? parseInt(match[5], 10) : 0
        };
    };

    const pv1 = parseVersion(v1);
    const pv2 = parseVersion(v2);

    if (pv1.major !== pv2.major) return pv2.major - pv1.major;
    if (pv1.minor !== pv2.minor) return pv2.minor - pv1.minor;
    if (pv1.patch !== pv2.patch) return pv2.patch - pv1.patch;
    if (pv1.prerelease !== pv2.prerelease) {
        const prereleaseOrder = { 'alpha': 0, 'beta': 1, 'stable': 2 };
        return prereleaseOrder[pv2.prerelease] - prereleaseOrder[pv1.prerelease];
    }
    return pv2.prereleaseNum - pv1.prereleaseNum;
}

async function getLatestVersion(featureId) {
    const strategy = STRATEGIES[featureId];
    if (!strategy) return null;

    try {
        if (strategy.type === 'github-release') {
            const release = await fetchJson(`https://api.github.com/repos/${strategy.repo}/releases/latest`);
            return release.tag_name ? release.tag_name.replace(/^v/, '') : null;
        } else if (strategy.type === 'npm') {
            const tags = strategy.distTags || ['latest'];
            let bestVersion = null;

            for (const tag of tags) {
                const pkg = await fetchJson(`https://registry.npmjs.org/${strategy.package}/${tag}`);
                const version = pkg.version;

                if (!bestVersion) {
                    bestVersion = version;
                    console.log(`  ${featureId} ${tag}: ${version}`);
                } else if (compareVersions(bestVersion, version) > 0) {
                    console.log(`  ${featureId} ${tag}: ${version} (newer than ${bestVersion})`);
                    bestVersion = version;
                } else {
                    console.log(`  ${featureId} ${tag}: ${version}`);
                }
            }

            return bestVersion;
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
