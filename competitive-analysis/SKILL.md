---
name: competitive-analysis
description: Compare local codebase capabilities against competitor products by researching competitor features via web search and documentation, analyzing local code patterns, and generating an interactive HTML comparison report.
license: MIT
compatibility: Requires internet access for web searches, basic CLI tools (grep, find), and a web browser for viewing results.
metadata:
  author: GitHub Copilot
  version: "1.0"
allowed-tools: grep glob view web_search web_fetch bash
---

# Competitive Analysis

Perform a comprehensive competitive analysis comparing your local codebase capabilities against competitor products. This skill researches competitor features, analyzes your codebase, and generates an interactive HTML report.

## When to Use

- Planning product roadmaps and identifying feature gaps
- Conducting market research for competitive positioning
- Evaluating technical capabilities against industry standards
- Creating feature parity assessments
- User asks to "compare our product against [competitor]"
- Preparing for investor or stakeholder presentations

## Instructions

### 1. Gather Requirements

Ask the user to clarify (if not provided):
- **Competitor name**: Which product/company to compare against?
- **Competitor website/docs**: URL to their product documentation (optional, will search if not provided)
- **Focus areas**: Specific feature categories or capabilities to compare (e.g., "API features", "security", "integrations", "UI components")
- **Local codebase scope**: Specific directories or components to analyze (defaults to entire repository)

### 2. Research Competitor Capabilities

**Step 2a: Web Search for Features**

Use `web_search` tool to discover competitor features:
```
Query examples:
- "[Competitor] features list"
- "[Competitor] product capabilities documentation"
- "[Competitor] API reference"
- "[Competitor] vs alternatives comparison"
```

Gather information about:
- Core features and functionality
- Technical capabilities (APIs, integrations, protocols)
- Platform support and deployment options
- Pricing tiers and feature availability
- Recent updates or announcements

**Step 2b: Fetch Documentation**

If competitor has public documentation:
```bash
# Use web_fetch tool to retrieve specific documentation pages
```

Focus on:
- Feature documentation pages
- API reference documentation
- Release notes or changelog
- Technical specifications

**Step 2c: Organize Competitor Features**

Create a structured list categorizing:
- **Category**: (e.g., Authentication, Data Processing, Integrations)
  - Feature name
  - Description
  - Key capabilities
  - Technical details

### 3. Analyze Local Codebase

**Step 3a: Discover Code Structure**

Use `glob` to understand project layout:
```bash
# Find main directories and file types
glob: "**/*" (with appropriate filters)
```

Identify:
- Programming languages used
- Framework and architecture patterns
- Main functional modules
- Configuration files

**Step 3b: Search for Feature Implementations**

For each competitor feature category, search your codebase:

```bash
# Use grep tool to find relevant implementations
grep pattern: "authentication|auth|login|oauth"
grep pattern: "api|endpoint|route"
grep pattern: "integration|webhook|connector"
grep pattern: "export|import|sync"
```

Search strategies:
- Keywords from competitor feature descriptions
- Common implementation patterns (class names, function names)
- Framework-specific patterns (decorators, annotations)
- Configuration keys and environment variables

**Step 3c: Analyze Implementation Depth**

For each found capability, assess:
- **Exists**: Feature is implemented
- **Partial**: Basic implementation exists but lacks depth
- **Missing**: No evidence of implementation
- **Superior**: Implementation exceeds competitor capability

Check for:
- Core functionality files
- Test coverage
- Documentation/README mentions
- API endpoints or interfaces
- Configuration options

### 4. Build Comparison Matrix

Create a structured comparison:

```
Category: [Feature Category]
├── Feature 1
│   ├── Competitor: [Description + Details]
│   ├── Local: [Status: Exists/Partial/Missing/Superior]
│   ├── Evidence: [File paths, code snippets, notes]
│   └── Gap Analysis: [What's missing or different]
├── Feature 2
│   └── ...
```

Calculate metrics:
- **Feature Parity Score**: % of competitor features implemented
- **Feature Gap Count**: Number of missing features
- **Competitive Advantages**: Features you have that competitor doesn't
- **Category Scores**: Parity by feature category

### 5. Generate HTML Report

Create an interactive HTML file with:

**Structure:**
```html
<!DOCTYPE html>
<html>
<head>
    <title>Competitive Analysis: [Your Product] vs [Competitor]</title>
    <style>
        /* Professional styling with dark mode support */
        /* Responsive design */
        /* Color-coded status indicators */
    </style>
</head>
<body>
    <header>
        <h1>Competitive Analysis</h1>
        <div class="metadata">
            <p>Comparison: [Your Product] vs [Competitor]</p>
            <p>Date: [Generated Date]</p>
            <p>Repository: [Path]</p>
        </div>
    </header>
    
    <section class="summary">
        <h2>Executive Summary</h2>
        <div class="metrics">
            <div class="metric">Feature Parity: [X%]</div>
            <div class="metric">Total Features Analyzed: [N]</div>
            <div class="metric">Competitive Advantages: [N]</div>
            <div class="metric">Feature Gaps: [N]</div>
        </div>
        <div class="insights">
            <h3>Key Insights</h3>
            <ul>
                <li>Major strengths</li>
                <li>Critical gaps</li>
                <li>Strategic recommendations</li>
            </ul>
        </div>
    </section>
    
    <section class="comparison">
        <h2>Feature Comparison</h2>
        <!-- For each category -->
        <div class="category">
            <h3>[Category Name]</h3>
            <div class="category-score">Parity: [X%]</div>
            <table>
                <thead>
                    <tr>
                        <th>Feature</th>
                        <th>Competitor</th>
                        <th>Your Product</th>
                        <th>Status</th>
                        <th>Evidence</th>
                    </tr>
                </thead>
                <tbody>
                    <tr class="status-[exists|partial|missing|superior]">
                        <td>[Feature Name]</td>
                        <td>[Competitor Description]</td>
                        <td>[Your Implementation Details]</td>
                        <td><span class="badge">[Status]</span></td>
                        <td>[File paths, notes]</td>
                    </tr>
                </tbody>
            </table>
        </div>
    </section>
    
    <section class="recommendations">
        <h2>Strategic Recommendations</h2>
        <div class="priority-high">
            <h3>High Priority</h3>
            <ul><!-- Critical gaps to address --></ul>
        </div>
        <div class="priority-medium">
            <h3>Medium Priority</h3>
            <ul><!-- Important but not urgent --></ul>
        </div>
        <div class="priority-low">
            <h3>Low Priority</h3>
            <ul><!-- Nice to have --></ul>
        </div>
    </section>
    
    <footer>
        <p>Generated by GitHub Copilot Competitive Analysis Skill</p>
        <p>This is an automated analysis. Verify findings independently.</p>
    </footer>
</body>
</html>
```

**Styling Guidelines:**
- Use color-coded badges: Green (Exists), Yellow (Partial), Red (Missing), Blue (Superior)
- Responsive table design with collapsible sections
- Dark mode support with CSS variables
- Printable layout with `@media print` styles
- Search/filter functionality with JavaScript (optional)

### 6. Save and Open Report

```bash
# Save HTML to a file
# Filename: competitive-analysis-[competitor]-[date].html

# Open in default browser
open competitive-analysis-[competitor]-[date].html  # macOS
xdg-open competitive-analysis-[competitor]-[date].html  # Linux
start competitive-analysis-[competitor]-[date].html  # Windows
```

### 7. Provide Summary

After opening the report, provide a brief summary:
- Total features analyzed
- Feature parity percentage
- Top 3 competitive advantages
- Top 3 critical gaps
- Link to the HTML file path

## Output Format

The skill produces:

1. **HTML Report File**: `competitive-analysis-[competitor]-YYYY-MM-DD.html`
   - Interactive, self-contained HTML document
   - Opens automatically in default browser
   - Can be shared with stakeholders

2. **Console Summary**:
   ```
   Competitive Analysis Complete
   =============================
   Competitor: [Name]
   Repository: [Path]
   
   Feature Parity: XX%
   Total Features Analyzed: N
   Competitive Advantages: N
   Feature Gaps: N
   
   Top Strengths:
   - [Advantage 1]
   - [Advantage 2]
   
   Critical Gaps:
   - [Gap 1]
   - [Gap 2]
   
   Report saved to: [file path]
   Opening in browser...
   ```

## Examples

### Example 1: Basic Comparison

**User Request:**
> Compare our API against Stripe's payment API

**Execution:**
1. Research Stripe API features (payment methods, webhooks, subscriptions, etc.)
2. Search codebase for payment-related implementations
3. Generate report showing feature-by-feature comparison
4. Open HTML report in browser

### Example 2: Focused Analysis

**User Request:**
> Compare our authentication features against Auth0, focusing on security and integrations

**Execution:**
1. Research Auth0 authentication capabilities (OAuth, SSO, MFA, social logins)
2. Search codebase for auth patterns in specified scope
3. Generate targeted report on authentication features only
4. Highlight security gaps and integration opportunities

### Example 3: Full Product Comparison

**User Request:**
> Do a complete competitive analysis against Notion, covering all major features

**Execution:**
1. Research Notion's full feature set (documents, databases, collaboration, API, etc.)
2. Analyze entire codebase for comparable features
3. Generate comprehensive report across all categories
4. Provide strategic roadmap recommendations

## Notes

### Important Considerations

- **Accuracy**: Web search results may be outdated. Verify critical findings against official documentation.
- **Scope**: Large codebases may require focused analysis on specific modules. Consider limiting scope for faster results.
- **Privacy**: This skill only analyzes local code; no code is shared externally. Web searches are for public competitor information only.
- **Interpretation**: Automated code analysis may miss features implemented in non-standard ways. Manual review is recommended.
- **Competitive Intelligence**: Focus on publicly available information only. Do not attempt to access private/proprietary competitor data.

### Edge Cases

- **Competitor documentation unavailable**: Rely more heavily on web search and third-party reviews/comparisons
- **Multi-language codebases**: Search patterns should adapt to different languages (e.g., Java annotations vs Python decorators)
- **Monorepo**: Specify subdirectory to focus analysis on relevant section
- **New/small codebase**: Report should acknowledge early-stage status and frame gaps as opportunities
- **Different product paradigms**: Note when direct feature comparison isn't applicable (e.g., SaaS vs self-hosted)

### Performance Tips

- **Parallel searches**: Use multiple `grep` calls simultaneously for different feature categories
- **Incremental analysis**: For large competitors, analyze one category at a time
- **Cache research**: Save competitor feature lists for reuse in future analyses
- **Focused patterns**: Use specific search patterns rather than broad wildcards

### Extending the Skill

To enhance this skill, consider:
- Adding JSON export option for programmatic access
- Creating time-series tracking (comparing reports over time)
- Integrating with issue tracker to auto-create feature tickets
- Adding screenshots of competitor features (using tools with headless browser support)
- Generating slide deck format (e.g., Markdown for Marp or reveal.js)

## Troubleshooting

**Issue**: Web searches return irrelevant results
- **Solution**: Refine search queries to be more specific, include version numbers or "documentation"

**Issue**: Can't find evidence of features known to exist
- **Solution**: Expand search patterns, check for alternative naming conventions, search in tests or docs folders

**Issue**: Report doesn't open in browser
- **Solution**: Provide file path for manual opening, check OS-specific open commands

**Issue**: Too many false positives in code search
- **Solution**: Narrow search scope, use more specific patterns, exclude test/vendor directories

**Issue**: Competitor has hundreds of features
- **Solution**: Focus on core/popular features, group related features, or limit to specific product areas
