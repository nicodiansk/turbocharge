// ABOUTME: Core library for skill discovery and resolution in the turbocharge plugin.
// ABOUTME: Handles YAML frontmatter extraction, skill file discovery, and namespace resolution.

import fs from 'fs';
import path from 'path';
import { execSync } from 'child_process';

const MAX_SKILL_SEARCH_DEPTH = 3;
const GIT_FETCH_TIMEOUT_MS = 3000;

/**
 * Extract YAML frontmatter from a skill file.
 * Current format:
 * ---
 * name: skill-name
 * description: Use when [condition] - [what it does]
 * ---
 *
 * @param {string} filePath - Path to SKILL.md file
 * @param {Object} options - Optional configuration
 * @param {Function} options.onError - Error callback function
 * @returns {{name: string, description: string}}
 */
function extractFrontmatter(filePath, options = {}) {
    try {
        const content = fs.readFileSync(filePath, 'utf8');
        const lines = content.split('\n');

        let inFrontmatter = false;
        let name = '';
        let description = '';

        for (const line of lines) {
            if (line.trim() === '---') {
                if (inFrontmatter) break;
                inFrontmatter = true;
                continue;
            }

            if (inFrontmatter) {
                const match = line.match(/^(\w+):\s*(.*)$/);
                if (match) {
                    const [, key, value] = match;
                    switch (key) {
                        case 'name':
                            name = value.trim();
                            break;
                        case 'description':
                            description = value.trim();
                            break;
                    }
                }
            }
        }

        return { name, description };
    } catch (error) {
        if (options.onError) {
            options.onError(`Failed to read frontmatter from ${filePath}: ${error.message}`);
        }
        return { name: '', description: '' };
    }
}

/**
 * Find all SKILL.md files in a directory recursively.
 *
 * @param {string} dir - Directory to search
 * @param {string} sourceType - 'personal' or 'turbocharge' for namespacing
 * @param {number} maxDepth - Maximum recursion depth
 * @returns {Array<{path: string, name: string, description: string, sourceType: string}>}
 */
function findSkillsInDir(dir, sourceType, maxDepth = MAX_SKILL_SEARCH_DEPTH) {
    const skills = [];

    if (!fs.existsSync(dir)) return skills;

    function recurse(currentDir, depth) {
        if (depth > maxDepth) return;

        const entries = fs.readdirSync(currentDir, { withFileTypes: true });

        for (const entry of entries) {
            const fullPath = path.join(currentDir, entry.name);

            if (entry.isDirectory()) {
                // Check for SKILL.md in this directory
                const skillFile = path.join(fullPath, 'SKILL.md');
                if (fs.existsSync(skillFile)) {
                    const { name, description } = extractFrontmatter(skillFile);
                    skills.push({
                        path: fullPath,
                        skillFile: skillFile,
                        name: name || entry.name,
                        description: description || '',
                        sourceType: sourceType
                    });
                }

                // Recurse into subdirectories
                recurse(fullPath, depth + 1);
            }
        }
    }

    recurse(dir, 0);
    return skills;
}

/**
 * Resolve a skill name to its file path, handling shadowing
 * (personal skills override turbocharge skills).
 *
 * @param {string} skillName - Name like "turbocharge:brainstorming" or "my-skill"
 * @param {string} turbochargeDir - Path to turbocharge skills directory
 * @param {string} personalDir - Path to personal skills directory
 * @returns {{skillFile: string, sourceType: string, skillPath: string} | null}
 */
function resolveSkillPath(skillName, turbochargeDir, personalDir) {
    // Strip turbocharge: prefix if present
    const forceTurbocharge = skillName.startsWith('turbocharge:');
    const actualSkillName = forceTurbocharge ? skillName.replace(/^turbocharge:/, '') : skillName;

    // Try personal skills first (unless explicitly turbocharge:)
    if (!forceTurbocharge && personalDir) {
        const personalPath = path.join(personalDir, actualSkillName);
        const personalSkillFile = path.join(personalPath, 'SKILL.md');
        if (fs.existsSync(personalSkillFile)) {
            return {
                skillFile: personalSkillFile,
                sourceType: 'personal',
                skillPath: actualSkillName
            };
        }
    }

    // Try turbocharge skills
    if (turbochargeDir) {
        const turbochargePath = path.join(turbochargeDir, actualSkillName);
        const turbochargeSkillFile = path.join(turbochargePath, 'SKILL.md');
        if (fs.existsSync(turbochargeSkillFile)) {
            return {
                skillFile: turbochargeSkillFile,
                sourceType: 'turbocharge',
                skillPath: actualSkillName
            };
        }
    }

    return null;
}

/**
 * Check if a git repository has updates available.
 *
 * @param {string} repoDir - Path to git repository
 * @returns {boolean} - True if updates are available
 */
function checkForUpdates(repoDir) {
    try {
        // Validate repoDir is a safe path with a .git directory
        const normalized = path.normalize(repoDir);
        if (!fs.existsSync(path.join(normalized, '.git'))) {
            return false;
        }

        const output = execSync('git fetch origin && git status --porcelain=v1 --branch', {
            cwd: normalized,
            timeout: GIT_FETCH_TIMEOUT_MS,
            encoding: 'utf8',
            stdio: 'pipe'
        });

        // Parse git status output to see if we're behind
        const statusLines = output.split('\n');
        for (const line of statusLines) {
            if (line.startsWith('## ') && line.includes('[behind ')) {
                return true; // We're behind remote
            }
        }
        return false; // Up to date
    } catch (error) {
        // Network down, git error, timeout, etc. - don't block bootstrap
        return false;
    }
}

/**
 * Strip YAML frontmatter from skill content, returning just the content.
 * Handles malformed frontmatter by returning original content if no closing delimiter.
 *
 * @param {string} content - Full content including frontmatter
 * @returns {string} - Content without frontmatter
 */
function stripFrontmatter(content) {
    const lines = content.split('\n');
    let frontmatterStartLine = -1;
    let frontmatterEndLine = -1;

    // Find frontmatter boundaries
    for (let i = 0; i < lines.length; i++) {
        if (lines[i].trim() === '---') {
            if (frontmatterStartLine === -1) {
                frontmatterStartLine = i;
            } else {
                frontmatterEndLine = i;
                break;
            }
        }
    }

    // Valid frontmatter requires both start and end delimiters
    if (frontmatterStartLine === -1 || frontmatterEndLine === -1) {
        return content.trim();
    }

    // Return everything after the closing delimiter
    return lines.slice(frontmatterEndLine + 1).join('\n').trim();
}

export {
    extractFrontmatter,
    findSkillsInDir,
    resolveSkillPath,
    checkForUpdates,
    stripFrontmatter
};
