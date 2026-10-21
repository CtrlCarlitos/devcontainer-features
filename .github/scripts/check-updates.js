const fs = require('fs');
const path = require('path');
const https = require('https');
const { execSync } = require('child_process');

const FEATURES_DIR = path.join(__dirname, '../../src');

// Exact user-facing version defaults. Floating selectors and compatibility
// majors intentionally do not need an update strategy.
const STRATEGIES = {
    'nerd-font': {
        type: 'github-release',
        repo: 'ryanoasis/nerd-fonts',
        syncInstallFallback: true
    },
    'codex': { type: 'npm', package: '@openai/codex' },
    'opencode': { type: 'npm', package: 'opencode-ai' },
    'claude-code': { type: 'npm', package: '@anthropic-ai/claude-code' },
    'guardrail': {
        type: 'github-release',
        repo: 'CtrlCarlitos/agent-guardrails',
        keepTag: true,
        requiredAssets: ['guardrail_linux_amd64', 'SHA256SUMS'],
        syncInstallFallback: true
    }
};

// Pinned installer dependencies that are not exposed as feature options.
const INSTALLER_DEPENDENCIES = {
    'nvm': {
        type: 'github-release',
        repo: 'nvm-sh/nvm',
        keepTag: true,
        targets: [
            { feature: 'runtime_core', file: 'runtime_core/install.sh', kind: 'nvm-url' },
            { feature: 'agent-browser', file: 'agent-browser/install.sh', kind: 'nvm-url' },
            { feature: 'playwright', file: 'playwright/install.sh', kind: 'nvm-url' },
            { feature: 'graft', file: 'graft/install.sh', kind: 'nvm-url' }
        ]
    },
    'modern-cli-bat': {
        type: 'github-release',
        repo: 'sharkdp/bat',
        keepTag: true,
        requiredAssets: [
            'bat-{version}-x86_64-unknown-linux-musl.tar.gz',
            'bat-{version}-aarch64-unknown-linux-musl.tar.gz'
        ],
        targets: [{ feature: 'modern-cli', file: 'modern-cli/install.sh', variable: 'BAT_VERSION' }]
    },
    'modern-cli-eza': {
        type: 'github-release',
        repo: 'eza-community/eza',
        keepTag: true,
        requiredAssets: [
            'eza_x86_64-unknown-linux-gnu.tar.gz',
            'eza_aarch64-unknown-linux-gnu.tar.gz'
        ],
        targets: [{ feature: 'modern-cli', file: 'modern-cli/install.sh', variable: 'EZA_VERSION' }]
    },
    'modern-cli-fd': {
        type: 'github-release',
        repo: 'sharkdp/fd',
        keepTag: true,
        requiredAssets: [
            'fd-{version}-x86_64-unknown-linux-musl.tar.gz',
            'fd-{version}-aarch64-unknown-linux-musl.tar.gz'
        ],
        targets: [{ feature: 'modern-cli', file: 'modern-cli/install.sh', variable: 'FD_VERSION' }]
    },
    'modern-cli-ripgrep': {
        type: 'github-release',
        repo: 'BurntSushi/ripgrep',
        requiredAssets: [
            'ripgrep-{version}-x86_64-unknown-linux-musl.tar.gz',
            'ripgrep-{version}-aarch64-unknown-linux-musl.tar.gz'
        ],
        targets: [{ feature: 'modern-cli', file: 'modern-cli/install.sh', variable: 'RIPGREP_VERSION' }]
    },
    'modern-cli-delta': {
        type: 'github-release',
        repo: 'dandavison/delta',
        requiredAssets: [
            'delta-{version}-x86_64-unknown-linux-gnu.tar.gz',
            'delta-{version}-aarch64-unknown-linux-gnu.tar.gz'
        ],
        targets: [{ feature: 'modern-cli', file: 'modern-cli/install.sh', variable: 'DELTA_VERSION' }]
    },
    'modern-cli-fzf': {
        type: 'github-release',
        repo: 'junegunn/fzf',
        requiredAssets: [
            'fzf-{version}-linux_amd64.tar.gz',
            'fzf-{version}-linux_arm64.tar.gz'
        ],
        targets: [{ feature: 'modern-cli', file: 'modern-cli/install.sh', variable: 'FZF_VERSION' }]
    },
    'modern-cli-jq': {
        type: 'github-release',
        repo: 'jqlang/jq',
        keepTag: true,
        requiredAssets: ['jq-linux-amd64', 'jq-linux-arm64'],
        targets: [{ feature: 'modern-cli', file: 'modern-cli/install.sh', variable: 'JQ_VERSION' }]
    },
    'modern-cli-duf': {
        type: 'github-release',
        repo: 'muesli/duf',
        keepTag: true,
        assetVersion: 'strip-v',
        requiredAssets: [
            'duf_{version}_linux_x86_64.tar.gz',
            'duf_{version}_linux_arm64.tar.gz'
        ],
        targets: [{ feature: 'modern-cli', file: 'modern-cli/install.sh', variable: 'DUF_VERSION' }]
    }
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

function syncInstallFallback(featureId, currentVersion, latestVersion) {
    const installPath = path.join(FEATURES_DIR, featureId, 'install.sh');
    const installScript = fs.readFileSync(installPath, 'utf8');
    const escapedVersion = currentVersion.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
    const updatedScript = installScript.replace(
        new RegExp(escapedVersion, 'g'),
        latestVersion
    );

    if (updatedScript === installScript) {
        throw new Error(`Could not update ${featureId} install.sh fallback version`);
    }

    fs.writeFileSync(installPath, updatedScript);
}

function syncInstallerDependency(target, version) {
    const installPath = path.join(FEATURES_DIR, target.file);
    const installScript = fs.readFileSync(installPath, 'utf8');
    let currentVersion = null;
    let updatedScript;

    if (target.variable) {
        const pattern = new RegExp(`^${target.variable}="([^"]+)"$`, 'm');
        const match = installScript.match(pattern);
        currentVersion = match?.[1] || null;
        updatedScript = installScript.replace(pattern, `${target.variable}="${version}"`);
    } else if (target.kind === 'nvm-url') {
        const pattern = /(nvm-sh\/nvm\/)([^/]+)(\/install\.sh)/g;
        const matches = [...installScript.matchAll(pattern)];
        currentVersion = matches[0]?.[2] || null;
        updatedScript = installScript.replace(pattern, `$1${version}$3`);
    } else {
        throw new Error(`Unknown installer dependency target for ${target.file}`);
    }

    if (!currentVersion) {
        throw new Error(`Could not read installer dependency version from ${target.file}`);
    }

    if (currentVersion === version) return false;
    if (compareVersions(currentVersion, version) <= 0) {
        console.log(`  ${target.file}: keeping newer version ${currentVersion} (candidate: ${version})`);
        return false;
    }
    if (updatedScript === installScript) {
        throw new Error(`Could not update installer dependency in ${target.file}`);
    }

    fs.writeFileSync(installPath, updatedScript);
    console.log(`  ${target.file}: ${currentVersion} -> ${version}`);
    return true;
}

function bumpFeatureVersion(featureId) {
    const featureJsonPath = path.join(FEATURES_DIR, featureId, 'devcontainer-feature.json');
    const featureJson = JSON.parse(fs.readFileSync(featureJsonPath, 'utf8'));
    const versionParts = featureJson.version?.split('.').map(Number);

    if (!versionParts || versionParts.length !== 3 || versionParts.some(isNaN)) {
        throw new Error(`Could not bump ${featureId} feature version`);
    }

    versionParts[2]++;
    const newVersion = versionParts.join('.');
    console.log(`  Bumping ${featureId} feature version: ${featureJson.version} -> ${newVersion}`);
    featureJson.version = newVersion;
    fs.writeFileSync(featureJsonPath, `${JSON.stringify(featureJson, null, 4)}\n`);
}

function compareVersions(v1, v2) {
    const parseVersion = (version) => {
        const normalized = version.replace(/^(?:v|jq-)/, '');
        const match = normalized.match(/^(\d+)\.(\d+)\.(\d+)(?:-([0-9A-Za-z.-]+))?$/);
        if (!match) throw new Error(`Unsupported version format: ${version}`);
        return {
            core: match.slice(1, 4).map(Number),
            prerelease: match[4]?.split('.') || null
        };
    };

    const pv1 = parseVersion(v1);
    const pv2 = parseVersion(v2);

    for (let index = 0; index < pv1.core.length; index++) {
        if (pv1.core[index] !== pv2.core[index]) {
            return pv2.core[index] - pv1.core[index];
        }
    }

    if (!pv1.prerelease && !pv2.prerelease) return 0;
    if (!pv1.prerelease) return -1;
    if (!pv2.prerelease) return 1;

    const identifierCount = Math.max(pv1.prerelease.length, pv2.prerelease.length);
    for (let index = 0; index < identifierCount; index++) {
        const identifier1 = pv1.prerelease[index];
        const identifier2 = pv2.prerelease[index];
        if (identifier1 === undefined) return 1;
        if (identifier2 === undefined) return -1;
        if (identifier1 === identifier2) continue;

        const numeric1 = /^\d+$/.test(identifier1);
        const numeric2 = /^\d+$/.test(identifier2);
        if (numeric1 && numeric2) return Number(identifier2) - Number(identifier1);
        if (numeric1 !== numeric2) return numeric1 ? 1 : -1;
        return identifier2 > identifier1 ? 1 : -1;
    }

    return 0;
}

async function getLatestVersion(id, strategy) {
    try {
        if (strategy.type === 'github-release') {
            const release = await fetchJson(`https://api.github.com/repos/${strategy.repo}/releases/latest`);
            if (!release.tag_name) return null;
            const version = strategy.keepTag
                ? release.tag_name
                : release.tag_name.replace(/^v/, '');
            const assetVersion = strategy.assetVersion === 'strip-v'
                ? release.tag_name.replace(/^v/, '')
                : version;
            const releaseAssets = new Set((release.assets || []).map(({ name }) => name));
            const missingAssets = (strategy.requiredAssets || [])
                .map((name) => name.replaceAll('{version}', assetVersion))
                .filter((name) => !releaseAssets.has(name));

            if (missingAssets.length > 0) {
                throw new Error(`release ${release.tag_name} is missing assets: ${missingAssets.join(', ')}`);
            }

            return version;
        } else if (strategy.type === 'npm') {
            const tags = strategy.distTags || ['latest'];
            let bestVersion = null;

            for (const tag of tags) {
                const pkg = await fetchJson(`https://registry.npmjs.org/${strategy.package}/${tag}`);
                const version = pkg.version;

                if (!bestVersion) {
                    bestVersion = version;
                    console.log(`  ${id} ${tag}: ${version}`);
                } else if (compareVersions(bestVersion, version) > 0) {
                    console.log(`  ${id} ${tag}: ${version} (newer than ${bestVersion})`);
                    bestVersion = version;
                } else {
                    console.log(`  ${id} ${tag}: ${version}`);
                }
            }

            return bestVersion;
        }
    } catch (error) {
        console.error(`Failed to check version for ${id}:`, error.message);
        return null;
    }
}

async function updateFeatures() {
    const featuresToBump = new Set();

    for (const [feature, strategy] of Object.entries(STRATEGIES)) {
        const featureJsonPath = path.join(FEATURES_DIR, feature, 'devcontainer-feature.json');
        const featureJson = JSON.parse(fs.readFileSync(featureJsonPath, 'utf8'));
        const currentDefault = featureJson.options?.version?.default;

        if (!currentDefault) {
            console.log(`Skipping ${feature}: no default version option found.`);
            continue;
        }

        const latest = await getLatestVersion(feature, strategy);

        if (
            latest &&
            latest !== currentDefault &&
            latest !== 'latest' &&
            currentDefault !== 'latest' &&
            compareVersions(currentDefault, latest) > 0
        ) {
            console.log(`Update available for ${feature}: ${currentDefault} -> ${latest}`);
            featureJson.options.version.default = latest;

            if (strategy.syncInstallFallback) {
                syncInstallFallback(feature, currentDefault, latest);
            }

            fs.writeFileSync(featureJsonPath, `${JSON.stringify(featureJson, null, 4)}\n`);
            featuresToBump.add(feature);
        } else if (latest) {
            console.log(`No update needed for ${feature} (Current: ${currentDefault}, Latest: ${latest})`);
        }
    }

    for (const [dependency, strategy] of Object.entries(INSTALLER_DEPENDENCIES)) {
        const latest = await getLatestVersion(dependency, strategy);
        if (!latest) continue;

        for (const target of strategy.targets) {
            if (syncInstallerDependency(target, latest)) {
                featuresToBump.add(target.feature);
            }
        }
    }

    for (const feature of [...featuresToBump].sort()) {
        bumpFeatureVersion(feature);
    }

    if (featuresToBump.size > 0) {
        setOutput('updated', 'true');
    }
}

updateFeatures();
