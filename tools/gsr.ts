import { tool } from "@opencode-ai/plugin"
import * as fs from "fs/promises"
import * as path from "path"

interface GSRResult {
  filesProcessed: number
  matchesFound: number
  replacements: number
  errors: Array<{ file: string; error: string }>
  modifiedFiles: string[]
}

export default tool({
  description: "Global Search & Replace - Perform precise, large-scale code refactors across the entire repository. Finds and replaces text patterns in multiple files efficiently without manually opening each file. Supports regex patterns, file filtering, and dry-run preview mode.",
  args: {
    search: tool.schema.string().describe("Text or regex pattern to search for"),
    replace: tool.schema.string().describe("Replacement text. Use $1, $2 for regex capture groups"),
    pattern: tool.schema.string().describe("Glob pattern for files to search (e.g., '**/*.ts', 'src/**/*.{js,ts}')").optional().default("**/*"),
    includeRegex: tool.schema.boolean().describe("Treat search pattern as regex (default: false)").optional().default(false),
    dryRun: tool.schema.boolean().describe("Preview mode - show what would change without modifying files").optional().default(false),
    ignoreCase: tool.schema.boolean().describe("Case-insensitive search").optional().default(false),
    wholeWord: tool.schema.boolean().describe("Match whole words only").optional().default(false),
  },
  async execute(args, context) {
    const cwd = context.worktree || context.directory
    const result: GSRResult = {
      filesProcessed: 0,
      matchesFound: 0,
      replacements: 0,
      errors: [],
      modifiedFiles: [],
    }

    const ignoreDirs = ['node_modules', '.git', 'dist', 'build', 'coverage', '.next', 'out', 'venv', '__pycache__', '.tox', 'vendor']
    
    const shouldInclude = (filePath: string): boolean => {
      const globPattern = args.pattern
      const relativePath = path.relative(cwd, filePath)
      
      if (ignoreDirs.some(dir => filePath.includes(`/${dir}/`) || filePath.startsWith(`${dir}/`))) {
        return false
      }
      
      const ext = path.extname(filePath)
      if (['.png', '.jpg', '.jpeg', '.gif', '.ico', '.svg', '.pdf', '.zip', '.tar', '.gz', '.lock'].includes(ext)) {
        return false
      }
      
      if (globPattern === '**/*') return true
      
      const patternRegex = globPattern
        .replace(/\./g, '\\.')
        .replace(/\*\*/g, '.*')
        .replace(/\*/g, '[^/]*')
        .replace(/\?/g, '.')
        .replace(/\{([^}]+)\}/g, (_, g) => `(${g.replace(/,/g, '|')})`)
      
      return new RegExp(`^${patternRegex}$`).test(relativePath)
    }

    const buildRegex = (): RegExp => {
      let pattern = args.search
      if (!args.includeRegex) {
        pattern = pattern.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')
      }
      if (args.wholeWord) {
        pattern = `\\b${pattern}\\b`
      }
      const flags = args.ignoreCase ? 'g' : 'gi'
      return new RegExp(pattern, args.includeRegex ? (args.ignoreCase ? 'g' : '') : 'gi')
    }

    const searchRegex = buildRegex()
    
    const files = await getAllFiles(cwd)
    
    for (const file of files) {
      if (!shouldInclude(file)) continue
      
      result.filesProcessed++
      const relativePath = path.relative(cwd, file)
      
      try {
        const content = await fs.readFile(file, 'utf-8')
        const matches = content.match(searchRegex)
        
        if (matches && matches.length > 0) {
          result.matchesFound += matches.length
          
          const newContent = content.replace(searchRegex, args.replace)
          
          if (args.dryRun) {
            const diff = generateDiff(content, newContent, relativePath)
            result.modifiedFiles.push(relativePath)
            console.log(`[DRY RUN] Would modify: ${relativePath} (${matches.length} replacements)`)
          } else {
            if (newContent !== content) {
              await fs.writeFile(file, newContent, 'utf-8')
              result.replacements += matches.length
              result.modifiedFiles.push(relativePath)
            }
          }
        }
      } catch (error) {
        result.errors.push({
          file: relativePath,
          error: error instanceof Error ? error.message : 'Unknown error',
        })
      }
    }

    const summary = generateSummary(result, args.dryRun)
    return summary
  },
})

async function getAllFiles(dir: string): Promise<string[]> {
  const files: string[] = []
  
  async function walk(currentDir: string) {
    const entries = await fs.readdir(currentDir, { withFileTypes: true })
    
    for (const entry of entries) {
      const fullPath = path.join(currentDir, entry.name)
      
      if (entry.isDirectory()) {
        await walk(fullPath)
      } else if (entry.isFile()) {
        files.push(fullPath)
      }
    }
  }
  
  await walk(dir)
  return files
}

function generateDiff(original: string, modified: string, filename: string): string {
  const origLines = original.split('\n')
  const modLines = modified.split('\n')
  let diff = `--- a/${filename}\n+++ b/${filename}\n`
  
  const maxLines = Math.max(origLines.length, modLines.length)
  for (let i = 0; i < maxLines; i++) {
    if (origLines[i] !== modLines[i]) {
      if (origLines[i] !== undefined) diff += `- ${origLines[i]}\n`
      if (modLines[i] !== undefined) diff += `+ ${modLines[i]}\n`
    }
  }
  
  return diff
}

function generateSummary(result: GSRResult, dryRun: boolean): string {
  const mode = dryRun ? "🔍 GSR PREVIEW MODE" : "✅ GSR COMPLETED"
  
  let summary = `# ${mode}\n\n`
  summary += `## Summary\n`
  summary += `- Files scanned: ${result.filesProcessed}\n`
  summary += `- Matches found: ${result.matchesFound}\n`
  
  if (dryRun) {
    summary += `- Files that would be modified: ${result.modifiedFiles.length}\n`
  } else {
    summary += `- Files modified: ${result.modifiedFiles.length}\n`
    summary += `- Total replacements: ${result.replacements}\n`
  }
  
  if (result.errors.length > 0) {
    summary += `\n## Errors (${result.errors.length})\n`
    for (const { file, error } of result.errors) {
      summary += `- ${file}: ${error}\n`
    }
  }
  
  if (result.modifiedFiles.length > 0 && dryRun) {
    summary += `\n## Files that would be modified:\n`
    summary += result.modifiedFiles.map(f => `- ${f}`).join('\n')
  } else if (result.modifiedFiles.length > 0) {
    summary += `\n## Modified files:\n`
    summary += result.modifiedFiles.map(f => `- ${f}`).join('\n')
  }
  
  if (result.matchesFound === 0) {
    summary += `\n⚠️ No matches found for the given pattern.`
  }
  
  return summary
}
