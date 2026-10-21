const fs = require('fs');
const path = require('path');

const repositoryRoot = path.resolve(__dirname, '../..');
const source = fs.readFileSync(
    path.join(repositoryRoot, '.github/scripts/check-updates.js'),
    'utf8'
);
const workflow = fs.readFileSync(
    path.join(repositoryRoot, '.github/workflows/auto-update.yml'),
    'utf8'
);
const strategies = source.match(/const STRATEGIES = \{([\s\S]*?)\n\};/);
const installerDependencies = source.match(
    /const INSTALLER_DEPENDENCIES = \{([\s\S]*?)\n\};/
);
const comparisonFunction = source.match(
    /function compareVersions\([\s\S]*?(?=\nasync function getLatestVersion)/
);

if (!strategies) {
    throw new Error('Could not find Auto-Update strategies');
}

if (!installerDependencies) {
    throw new Error('Could not find installer dependency strategies');
}

if (!comparisonFunction) {
    throw new Error('Could not find version comparison function');
}

const compareVersions = Function(`${comparisonFunction[0]}; return compareVersions;`)();
const versionOrderingCases = [
    ['v0.40.8', 'v0.40.7', false],
    ['v0.40.7', 'v0.40.8', true],
    ['jq-1.8.2', 'jq-1.8.1', false],
    ['v0.23.36-dev', 'v0.23.35-dev', false],
    ['v0.23.35-dev', 'v0.23.36-dev', true],
    ['v0.23.36-dev', 'v0.23.36', true],
    ['6.0.0-Beta.6', '6.0.0-Beta.7', true],
    ['6.0.0', '6.0.0-Beta.7', false],
    ['1.0.0-a', '1.0.0-B', false]
];

for (const [currentVersion, candidateVersion, expected] of versionOrderingCases) {
    const actual = compareVersions(currentVersion, candidateVersion) > 0;
    if (actual !== expected) {
        throw new Error(
            `Version ordering failed for ${currentVersion} -> ${candidateVersion}: ` +
            `expected newer=${expected}, got newer=${actual}`
        );
    }
}

const featureIds = [...strategies[1].matchAll(/^\s*'([^']+)':/gm)].map((match) => match[1]);
const missing = featureIds.filter(
    (featureId) => !fs.existsSync(
        path.join(repositoryRoot, 'src', featureId, 'devcontainer-feature.json')
    )
);

if (missing.length > 0) {
    throw new Error(`Auto-Update strategies without source features: ${missing.join(', ')}`);
}

const strategyIds = new Set(featureIds);
const sourceDirectory = path.join(repositoryRoot, 'src');
const floatingVersions = new Set(['latest', 'stable', 'lts', 'node']);
const missingPolicies = [];
const pinnedInstallerVariables = [];
const nvmPins = [];

for (const entry of fs.readdirSync(sourceDirectory, { withFileTypes: true })) {
    if (!entry.isDirectory()) continue;

    const metadataPath = path.join(sourceDirectory, entry.name, 'devcontainer-feature.json');
    if (!fs.existsSync(metadataPath)) continue;

    const metadata = JSON.parse(fs.readFileSync(metadataPath, 'utf8'));
    const defaultVersion = metadata.options?.version?.default;
    const normalizedVersion = typeof defaultVersion === 'string'
        ? defaultVersion.trim().toLowerCase()
        : '';

    if (
        normalizedVersion &&
        !floatingVersions.has(normalizedVersion) &&
        !/^\d+$/.test(normalizedVersion) &&
        !strategyIds.has(entry.name)
    ) {
        missingPolicies.push(`${entry.name} (${defaultVersion})`);
    }

    const installPath = path.join(sourceDirectory, entry.name, 'install.sh');
    if (!fs.existsSync(installPath)) continue;

    const installScript = fs.readFileSync(installPath, 'utf8');
    for (const match of installScript.matchAll(/^([A-Z][A-Z0-9_]*_VERSION)="([^"]+)"$/gm)) {
        pinnedInstallerVariables.push({ feature: entry.name, variable: match[1] });
    }

    for (const match of installScript.matchAll(/nvm-sh\/nvm\/([^/]+)\/install\.sh/g)) {
        nvmPins.push({ file: `${entry.name}/install.sh`, version: match[1] });
    }
}

if (missingPolicies.length > 0) {
    throw new Error(
        `Pinned version defaults without Auto-Update strategies: ${missingPolicies.sort().join(', ')}`
    );
}

const dependencySource = installerDependencies[1];
const dependencyPolicies = [...dependencySource.matchAll(
    /^    '([^']+)': \{([\s\S]*?)^    \}(?:,|$)/gm
)];
const assetlessBinaryPolicies = dependencyPolicies
    .filter(([, , policy]) => policy.includes('variable:') && !policy.includes('requiredAssets:'))
    .map(([, dependency]) => dependency);

if (assetlessBinaryPolicies.length > 0) {
    throw new Error(
        `Binary dependency strategies without required assets: ${assetlessBinaryPolicies.sort().join(', ')}`
    );
}

const uncoveredVariables = pinnedInstallerVariables.filter(({ feature, variable }) =>
    !dependencyPolicies.some(([, , policy]) =>
        policy.includes(`feature: '${feature}'`) && policy.includes(`variable: '${variable}'`)
    )
).map(({ feature, variable }) => `${feature}:${variable}`);

if (uncoveredVariables.length > 0) {
    throw new Error(
        `Pinned installer variables without Auto-Update strategies: ${uncoveredVariables.sort().join(', ')}`
    );
}

const nvmVersions = new Set(nvmPins.map(({ version }) => version));
if (nvmVersions.size > 1) {
    throw new Error(`nvm installer pins disagree: ${[...nvmVersions].sort().join(', ')}`);
}

const uncoveredNvmFiles = nvmPins
    .map(({ file }) => file)
    .filter((file) => !dependencySource.includes(`file: '${file}'`));

if (uncoveredNvmFiles.length > 0) {
    throw new Error(
        `nvm installer pins without Auto-Update strategies: ${uncoveredNvmFiles.sort().join(', ')}`
    );
}

const guardrailInstall = fs.readFileSync(
    path.join(sourceDirectory, 'guardrail', 'install.sh'),
    'utf8'
);
if (!guardrailInstall.includes('ASSET="guardrail_linux_amd64"')) {
    throw new Error('Guardrail must use the Linux release asset without a Windows .exe suffix');
}

const guardrailMetadata = JSON.parse(fs.readFileSync(
    path.join(sourceDirectory, 'guardrail', 'devcontainer-feature.json'),
    'utf8'
));
const guardrailDefault = guardrailMetadata.options.version.default;
const staleGuardrailVersions = [...guardrailInstall.matchAll(/v\d+\.\d+\.\d+-dev/g)]
    .map((match) => match[0])
    .filter((version) => version !== guardrailDefault);
if (staleGuardrailVersions.length > 0) {
    throw new Error(
        `Guardrail install.sh versions differ from metadata: ${[...new Set(staleGuardrailVersions)].join(', ')}`
    );
}

const modernCliInstall = fs.readFileSync(
    path.join(sourceDirectory, 'modern-cli', 'install.sh'),
    'utf8'
);
if (!modernCliInstall.includes('eza_${GNU}.tar.gz')) {
    throw new Error('Modern CLI must use Eza GNU release assets for both supported architectures');
}

if (!workflow.includes('client-id: ${{ secrets.UPDATER_APP_CLIENT_ID }}')) {
    throw new Error('Auto-Update must mint its token with UPDATER_APP_CLIENT_ID');
}

if (/^\s+app-id:/m.test(workflow)) {
    throw new Error('Auto-Update must not use the deprecated app-id input');
}

console.log(
    `Auto-Update covers ${featureIds.length} feature defaults, ` +
    `${pinnedInstallerVariables.length} installer variables, and ${nvmPins.length} nvm pins.`
);
