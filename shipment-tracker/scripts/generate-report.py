#!/usr/bin/env python3
"""
Generate an interactive HTML shipment report from GitHub PR and issue data.
Uses only Python standard library (no external dependencies).
"""

import json
import sys
import argparse
from datetime import datetime
from collections import defaultdict
from html import escape

HTML_TEMPLATE = """<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Shipment Report - {date_range}</title>
    <style>
        * {{
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }}
        body {{
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', 'Noto Sans', Helvetica, Arial, sans-serif;
            line-height: 1.6;
            color: #24292f;
            background: #f6f8fa;
            padding: 20px;
        }}
        .container {{
            max-width: 1200px;
            margin: 0 auto;
            background: white;
            padding: 40px;
            border-radius: 6px;
            box-shadow: 0 1px 3px rgba(0,0,0,0.12);
        }}
        h1 {{
            color: #24292f;
            margin-bottom: 10px;
            font-size: 32px;
        }}
        .subtitle {{
            color: #57606a;
            margin-bottom: 30px;
            font-size: 16px;
        }}
        .summary {{
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 20px;
            margin-bottom: 40px;
        }}
        .stat-card {{
            background: #f6f8fa;
            padding: 20px;
            border-radius: 6px;
            border: 1px solid #d0d7de;
        }}
        .stat-value {{
            font-size: 32px;
            font-weight: 600;
            color: #0969da;
            margin-bottom: 5px;
        }}
        .stat-label {{
            color: #57606a;
            font-size: 14px;
        }}
        .section {{
            margin-bottom: 40px;
        }}
        h2 {{
            color: #24292f;
            font-size: 24px;
            margin-bottom: 20px;
            padding-bottom: 10px;
            border-bottom: 1px solid #d0d7de;
        }}
        .repo-section {{
            margin-bottom: 30px;
        }}
        .repo-title {{
            font-size: 20px;
            font-weight: 600;
            color: #0969da;
            margin-bottom: 15px;
        }}
        .items-list {{
            list-style: none;
        }}
        .item {{
            padding: 12px;
            margin-bottom: 8px;
            background: #f6f8fa;
            border-radius: 6px;
            border-left: 3px solid #0969da;
            display: flex;
            justify-content: space-between;
            align-items: start;
        }}
        .item.pr {{
            border-left-color: #8250df;
        }}
        .item.issue {{
            border-left-color: #1a7f37;
        }}
        .item-main {{
            flex: 1;
        }}
        .item-title {{
            font-weight: 500;
            color: #24292f;
            margin-bottom: 4px;
        }}
        .item-title a {{
            color: #0969da;
            text-decoration: none;
        }}
        .item-title a:hover {{
            text-decoration: underline;
        }}
        .item-meta {{
            font-size: 13px;
            color: #57606a;
        }}
        .item-date {{
            font-size: 13px;
            color: #57606a;
            white-space: nowrap;
            margin-left: 20px;
        }}
        .badge {{
            display: inline-block;
            padding: 2px 8px;
            font-size: 12px;
            font-weight: 500;
            border-radius: 12px;
            margin-right: 4px;
        }}
        .badge.pr {{
            background: #8250df;
            color: white;
        }}
        .badge.issue {{
            background: #1a7f37;
            color: white;
        }}
        .label-badge {{
            display: inline-block;
            padding: 2px 8px;
            font-size: 11px;
            border-radius: 12px;
            background: #ddf4ff;
            color: #0969da;
            margin-right: 4px;
        }}
        .category-summary {{
            background: #f6f8fa;
            border: 1px solid #d0d7de;
            border-radius: 6px;
            padding: 20px;
            margin-bottom: 40px;
        }}
        .category-summary h3 {{
            color: #24292f;
            font-size: 18px;
            margin-bottom: 15px;
        }}
        .category-list {{
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
            gap: 15px;
        }}
        .category-item {{
            background: white;
            padding: 12px 15px;
            border-radius: 4px;
            border-left: 3px solid #0969da;
            font-size: 14px;
        }}
        .category-name {{
            font-weight: 600;
            color: #24292f;
            margin-bottom: 4px;
        }}
        .category-count {{
            color: #57606a;
            font-size: 13px;
        }}
        .timeline {{
            margin-bottom: 40px;
        }}
        .timeline-chart {{
            height: 200px;
            background: #f6f8fa;
            border-radius: 6px;
            padding: 20px;
            position: relative;
            border: 1px solid #d0d7de;
        }}
        .timeline-bars {{
            display: flex;
            height: 140px;
            align-items: flex-end;
            gap: 4px;
        }}
        .timeline-bar {{
            flex: 1;
            background: linear-gradient(180deg, #8250df 0%, #0969da 100%);
            border-radius: 3px 3px 0 0;
            min-height: 2px;
            position: relative;
            cursor: pointer;
            transition: opacity 0.2s;
        }}
        .timeline-bar:hover {{
            opacity: 0.8;
        }}
        .timeline-bar-tooltip {{
            display: none;
            position: absolute;
            bottom: 100%;
            left: 50%;
            transform: translateX(-50%);
            background: #24292f;
            color: white;
            padding: 6px 10px;
            border-radius: 4px;
            font-size: 12px;
            white-space: nowrap;
            margin-bottom: 5px;
        }}
        .timeline-bar:hover .timeline-bar-tooltip {{
            display: block;
        }}
        .filters {{
            margin-bottom: 20px;
            padding: 15px;
            background: #f6f8fa;
            border-radius: 6px;
        }}
        .filter-group {{
            display: inline-block;
            margin-right: 20px;
            margin-bottom: 10px;
        }}
        .filter-group label {{
            margin-right: 8px;
            font-size: 14px;
            color: #24292f;
        }}
        .filter-group select, .filter-group input {{
            padding: 5px 10px;
            border: 1px solid #d0d7de;
            border-radius: 4px;
            font-size: 14px;
        }}
        .empty-state {{
            text-align: center;
            padding: 40px;
            color: #57606a;
        }}
        .executive-summary {{
            background: white;
            border: 2px solid #0969da;
            border-radius: 6px;
            padding: 25px;
            margin-bottom: 40px;
        }}
        .executive-summary h3 {{
            color: #0969da;
            font-size: 20px;
            margin-bottom: 15px;
            display: flex;
            align-items: center;
            gap: 10px;
        }}
        .executive-summary-content {{
            background: #f6f8fa;
            padding: 20px;
            border-radius: 4px;
            font-family: 'Courier New', monospace;
            font-size: 13px;
            line-height: 1.8;
            white-space: pre-wrap;
            color: #24292f;
            max-height: 400px;
            overflow-y: auto;
        }}
        .copy-button {{
            background: #0969da;
            color: white;
            border: none;
            padding: 8px 16px;
            border-radius: 4px;
            font-size: 14px;
            cursor: pointer;
            margin-top: 10px;
        }}
        .copy-button:hover {{
            background: #0860ca;
        }}
        .copy-button:active {{
            background: #0757ba;
        }}
        @media (max-width: 768px) {{
            .container {{
                padding: 20px;
            }}
            .summary {{
                grid-template-columns: 1fr;
            }}
        }}
    </style>
</head>
<body>
    <div class="container">
        <h1>📦 Shipment Report</h1>
        <div class="subtitle">{date_range} • {repo_list}</div>
        
        <div class="summary">
            <div class="stat-card">
                <div class="stat-value">{total_prs}</div>
                <div class="stat-label">Pull Requests Merged</div>
            </div>
            <div class="stat-card">
                <div class="stat-value">{total_issues}</div>
                <div class="stat-label">Issues Closed</div>
            </div>
            <div class="stat-card">
                <div class="stat-value">{total_items}</div>
                <div class="stat-label">Total Items Shipped</div>
            </div>
            <div class="stat-card">
                <div class="stat-value">{total_contributors}</div>
                <div class="stat-label">Contributors</div>
            </div>
        </div>

        {executive_summary}

        {category_summary}

        <div class="section timeline">
            <h2>📊 Timeline</h2>
            <div class="timeline-chart">
                <div class="timeline-bars">
                    {timeline_bars}
                </div>
            </div>
        </div>

        <div class="section">
            <h2>🚀 Shipped Items</h2>
            <div class="filters">
                <div class="filter-group">
                    <label>Type:</label>
                    <select id="typeFilter" onchange="filterItems()">
                        <option value="all">All</option>
                        <option value="pr">PRs Only</option>
                        <option value="issue">Issues Only</option>
                    </select>
                </div>
                <div class="filter-group">
                    <label>Repository:</label>
                    <select id="repoFilter" onchange="filterItems()">
                        <option value="all">All Repositories</option>
                        {repo_options}
                    </select>
                </div>
                <div class="filter-group">
                    <label>Search:</label>
                    <input type="text" id="searchInput" placeholder="Filter by title..." oninput="filterItems()">
                </div>
            </div>
            
            <div id="itemsContainer">
                {items_html}
            </div>
        </div>
    </div>

    <script>
        function filterItems() {{
            const typeFilter = document.getElementById('typeFilter').value;
            const repoFilter = document.getElementById('repoFilter').value;
            const searchTerm = document.getElementById('searchInput').value.toLowerCase();
            
            const items = document.querySelectorAll('.item');
            items.forEach(item => {{
                const itemType = item.classList.contains('pr') ? 'pr' : 'issue';
                const itemRepo = item.dataset.repo;
                const itemTitle = item.querySelector('.item-title').textContent.toLowerCase();
                
                const typeMatch = typeFilter === 'all' || itemType === typeFilter;
                const repoMatch = repoFilter === 'all' || itemRepo === repoFilter;
                const searchMatch = searchTerm === '' || itemTitle.includes(searchTerm);
                
                if (typeMatch && repoMatch && searchMatch) {{
                    item.style.display = 'flex';
                }} else {{
                    item.style.display = 'none';
                }}
            }});
        }}
        
        function copyExecutiveSummary() {{
            const summaryText = document.getElementById('executiveSummaryText').textContent;
            navigator.clipboard.writeText(summaryText).then(() => {{
                const button = document.getElementById('copyButton');
                const originalText = button.textContent;
                button.textContent = '✓ Copied!';
                setTimeout(() => {{
                    button.textContent = originalText;
                }}, 2000);
            }});
        }}
    </script>
</body>
</html>
"""


def parse_date(date_str):
    """Parse ISO 8601 date string to datetime object."""
    try:
        return datetime.fromisoformat(date_str.replace('Z', '+00:00'))
    except:
        return datetime.strptime(date_str, '%Y-%m-%dT%H:%M:%SZ')


def format_date(date_str):
    """Format date string to human-readable format."""
    dt = parse_date(date_str)
    return dt.strftime('%b %d, %Y')


def generate_timeline_bars(items, since, until):
    """Generate HTML for timeline bar chart."""
    if not items:
        return '<div class="empty-state">No data to display</div>'
    
    # Group items by date
    date_counts = defaultdict(int)
    for item in items:
        date_key = item['date'][:10]  # YYYY-MM-DD
        date_counts[date_key] += 1
    
    if not date_counts:
        return '<div class="empty-state">No data to display</div>'
    
    # Generate bars (max 30 bars for readability)
    max_count = max(date_counts.values())
    sorted_dates = sorted(date_counts.keys())
    
    # Sample dates if too many
    if len(sorted_dates) > 30:
        step = len(sorted_dates) // 30
        sorted_dates = sorted_dates[::step]
    
    bars = []
    for date in sorted_dates:
        count = date_counts.get(date, 0)
        height_pct = (count / max_count * 100) if max_count > 0 else 0
        bars.append(f'''
            <div class="timeline-bar" style="height: {height_pct}%">
                <div class="timeline-bar-tooltip">{date}: {count} items</div>
            </div>
        ''')
    
    return ''.join(bars)


def categorize_item(title, item_type):
    """Categorize an item based on title and type."""
    title_lower = title.lower()
    
    if item_type == 'PR':
        if any(word in title_lower for word in ['skill', 'agent capability']):
            return 'New Skills & Agent Capabilities'
        elif any(word in title_lower for word in ['tool', 'function', 'mcp']):
            return 'Tools & Integrations'
        elif any(word in title_lower for word in ['fix', 'bug', 'error']):
            return 'Bug Fixes'
        elif any(word in title_lower for word in ['perf', 'performance', 'optimize', 'speed']):
            return 'Performance Improvements'
        else:
            return 'Other Features'
    else:  # Issue
        if any(word in title_lower for word in ['bug', 'fix', 'error', 'crash', 'fail']):
            return 'Bug Fixes'
        else:
            return 'Feature Requests & Enhancements'


def generate_category_summary(all_items):
    """Generate HTML for category summary section."""
    if not all_items:
        return ''
    
    # Categorize all items
    categories = defaultdict(int)
    for item in all_items:
        category = categorize_item(item['title'], item['type'])
        categories[category] += 1
    
    if not categories:
        return ''
    
    # Sort categories by count
    sorted_categories = sorted(categories.items(), key=lambda x: x[1], reverse=True)
    
    html_parts = []
    html_parts.append('<div class="category-summary">')
    html_parts.append('<h3>📋 Items by Category</h3>')
    html_parts.append('<div class="category-list">')
    
    for category, count in sorted_categories:
        html_parts.append(f'''
            <div class="category-item">
                <div class="category-name">{escape(category)}</div>
                <div class="category-count">{count} items</div>
            </div>
        ''')
    
    html_parts.append('</div>')
    html_parts.append('</div>')
    
    return ''.join(html_parts)


def generate_executive_summary(all_items, repos, date_range, total_prs, total_issues, total_contributors):
    """Generate executive summary text that can be copied."""
    if not all_items:
        return ''
    
    # Categorize all items
    categories = defaultdict(list)
    for item in all_items:
        category = categorize_item(item['title'], item['type'])
        categories[category].append(item)
    
    # Identify customer-facing features (exclude internal/infra items)
    def is_customer_facing(item):
        title_lower = item['title'].lower()
        
        # Exclude internal infrastructure
        if any(word in title_lower for word in ['chore:', 'chore ', 'test:', 'ci:', 'refactor:', 
                                                  'deps:', 'bump', 'migrate', 'cleanup', 
                                                  'internal', 'telemetry', 'logging']):
            return False
        
        # Include clear customer features
        if any(word in title_lower for word in ['skill', 'agent', 'tool', 'command', '/context', 
                                                  '/compact', 'slash', 'model', 'auth', 'login',
                                                  'handoff', 'continuity', 'resume', 'homebrew',
                                                  'winget', 'install', 'tab completion', 'picker',
                                                  'web fetch', 'github tool', 'mcp']):
            return True
        
        # Include bug fixes
        if item['type'] == 'PR' and any(word in title_lower for word in ['fix', 'bug', 'error']):
            return True
        
        return False
    
    customer_facing_items = [item for item in all_items if is_customer_facing(item)]
    
    # Sort categories by count
    sorted_categories = sorted(categories.items(), key=lambda x: len(x[1]), reverse=True)
    
    # Build text summary
    lines = []
    lines.append(f"SHIPMENT REPORT: {date_range}")
    lines.append(f"Repositories: {', '.join(repos)}")
    lines.append("")
    lines.append("EXECUTIVE SUMMARY")
    lines.append(f"• {len(customer_facing_items)} Customer-Facing Features Shipped")
    lines.append(f"• {total_prs} Total Pull Requests Merged")
    lines.append(f"• {total_issues} Issues Closed")
    lines.append(f"• {total_contributors} Contributors")
    lines.append("")
    lines.append("KEY CUSTOMER-FACING FEATURES")
    lines.append("")
    
    # Extract and group customer features by type
    feature_groups = defaultdict(list)
    for item in customer_facing_items:
        title = item['title']
        title_lower = title.lower()
        
        if any(word in title_lower for word in ['skill', 'agent']):
            feature_groups['New Agent Skills & Capabilities'].append(title)
        elif any(word in title_lower for word in ['/context', '/compact', 'slash', 'command']):
            feature_groups['New Commands & Features'].append(title)
        elif any(word in title_lower for word in ['tool', 'mcp', 'github', 'web fetch']):
            feature_groups['Tool Integrations'].append(title)
        elif any(word in title_lower for word in ['model', 'picker', 'llm']):
            feature_groups['Model Management'].append(title)
        elif any(word in title_lower for word in ['auth', 'login', 'device code']):
            feature_groups['Authentication'].append(title)
        elif any(word in title_lower for word in ['handoff', 'continuity', 'resume', 'remote']):
            feature_groups['Cross-Platform Continuity'].append(title)
        elif any(word in title_lower for word in ['homebrew', 'winget', 'install', 'publish']):
            feature_groups['Distribution & Installation'].append(title)
        elif any(word in title_lower for word in ['ui', 'ux', 'display', 'tab completion']):
            feature_groups['User Experience Improvements'].append(title)
        elif any(word in title_lower for word in ['fix', 'bug', 'error']):
            feature_groups['Bug Fixes'].append(title)
        else:
            feature_groups['Other Features'].append(title)
    
    # Sort feature groups by priority for executives
    priority_order = [
        'New Agent Skills & Capabilities',
        'New Commands & Features',
        'Tool Integrations',
        'Cross-Platform Continuity',
        'Model Management',
        'Distribution & Installation',
        'User Experience Improvements',
        'Authentication',
        'Bug Fixes',
        'Other Features'
    ]
    
    for group_name in priority_order:
        if group_name in feature_groups and feature_groups[group_name]:
            features = feature_groups[group_name]
            lines.append(f"{group_name} ({len(features)} items):")
            # Show top 8 items per category
            for feature in features[:8]:
                # Clean up the title for better readability
                clean_title = feature.replace('[CLI]', '').replace('[CLI/CCA]', '').replace('CLI:', '').strip()
                lines.append(f"  • {clean_title}")
            if len(features) > 8:
                lines.append(f"  • ...and {len(features) - 8} more")
            lines.append("")
    
    lines.append("")
    lines.append("DETAILED BREAKDOWN BY CATEGORY")
    for category, items in sorted_categories:
        lines.append(f"• {category}: {len(items)} items")
    
    summary_text = '\n'.join(lines)
    
    # Build HTML
    html = f'''
        <div class="executive-summary">
            <h3>
                <span>📄 Executive Summary</span>
            </h3>
            <div class="executive-summary-content" id="executiveSummaryText">{escape(summary_text)}</div>
            <button class="copy-button" id="copyButton" onclick="copyExecutiveSummary()">📋 Copy to Clipboard</button>
        </div>
    '''
    
    return html


def generate_items_html(items_by_repo):
    """Generate HTML for items list."""
    if not items_by_repo:
        return '<div class="empty-state">No items found in the specified time period.</div>'
    
    html_parts = []
    
    for repo, items in sorted(items_by_repo.items()):
        html_parts.append(f'<div class="repo-section">')
        html_parts.append(f'<div class="repo-title">{escape(repo)}</div>')
        html_parts.append('<ul class="items-list">')
        
        # Sort by date (most recent first)
        sorted_items = sorted(items, key=lambda x: x['date'], reverse=True)
        
        for item in sorted_items:
            item_type = item['type']
            type_class = 'pr' if item_type == 'PR' else 'issue'
            
            labels_html = ''
            if item.get('labels'):
                labels_html = ' '.join([
                    f'<span class="label-badge">{escape(label)}</span>'
                    for label in item['labels'][:5]  # Limit to 5 labels
                ])
            
            html_parts.append(f'''
                <li class="item {type_class}" data-repo="{escape(repo)}">
                    <div class="item-main">
                        <div class="item-title">
                            <span class="badge {type_class}">{item_type}</span>
                            <a href="{escape(item['url'])}" target="_blank">
                                #{item['number']} {escape(item['title'])}
                            </a>
                        </div>
                        <div class="item-meta">
                            by {escape(item['author'])}
                            {' • ' + labels_html if labels_html else ''}
                        </div>
                    </div>
                    <div class="item-date">{format_date(item['date'])}</div>
                </li>
            ''')
        
        html_parts.append('</ul>')
        html_parts.append('</div>')
    
    return ''.join(html_parts)


def load_json_stdin():
    """Load JSON data from stdin."""
    try:
        data = sys.stdin.read()
        if data.strip():
            return json.loads(data)
    except:
        pass
    return None


def main():
    parser = argparse.ArgumentParser(description='Generate shipment report HTML')
    parser.add_argument('--repos', required=True, help='Comma-separated list of repos')
    parser.add_argument('--since', required=True, help='Start date (YYYY-MM-DD)')
    parser.add_argument('--until', help='End date (YYYY-MM-DD)', default=None)
    parser.add_argument('--output', default='shipment-report.html', help='Output file')
    parser.add_argument('--prs-json', help='JSON file with PR data')
    parser.add_argument('--issues-json', help='JSON file with issues data')
    
    args = parser.parse_args()
    
    repos = [r.strip() for r in args.repos.split(',')]
    
    # Collect all items
    all_items = []
    items_by_repo = defaultdict(list)
    contributors = set()
    
    # Load data from JSON files if provided
    pr_data = {}
    issue_data = {}
    
    if args.prs_json:
        try:
            with open(args.prs_json, 'r') as f:
                pr_data = json.load(f)
        except:
            pass
    
    if args.issues_json:
        try:
            with open(args.issues_json, 'r') as f:
                issue_data = json.load(f)
        except:
            pass
    
    # Process PR data
    for repo, prs in pr_data.items():
        for pr in prs:
            item = {
                'type': 'PR',
                'number': pr['number'],
                'title': pr['title'],
                'author': pr['author']['login'],
                'date': pr['mergedAt'],
                'url': pr['url'],
                'labels': [label['name'] for label in pr.get('labels', [])]
            }
            all_items.append(item)
            items_by_repo[repo].append(item)
            contributors.add(item['author'])
    
    # Process issue data
    for repo, issues in issue_data.items():
        for issue in issues:
            item = {
                'type': 'Issue',
                'number': issue['number'],
                'title': issue['title'],
                'author': issue['author']['login'],
                'date': issue['closedAt'],
                'url': issue['url'],
                'labels': [label['name'] for label in issue.get('labels', [])]
            }
            all_items.append(item)
            items_by_repo[repo].append(item)
            contributors.add(item['author'])
    
    # Generate statistics
    total_prs = sum(1 for item in all_items if item['type'] == 'PR')
    total_issues = sum(1 for item in all_items if item['type'] == 'Issue')
    
    # Format date range
    until_str = args.until or datetime.now().strftime('%Y-%m-%d')
    date_range = f"{args.since} to {until_str}"
    
    # Generate repo options for filter
    repo_options = '\n'.join([
        f'<option value="{escape(repo)}">{escape(repo)}</option>'
        for repo in sorted(repos)
    ])
    
    # Generate HTML
    html = HTML_TEMPLATE.format(
        date_range=date_range,
        repo_list=', '.join(repos),
        total_prs=total_prs,
        total_issues=total_issues,
        total_items=len(all_items),
        total_contributors=len(contributors),
        executive_summary=generate_executive_summary(all_items, repos, date_range, total_prs, total_issues, len(contributors)),
        category_summary=generate_category_summary(all_items),
        timeline_bars=generate_timeline_bars(all_items, args.since, until_str),
        items_html=generate_items_html(items_by_repo),
        repo_options=repo_options
    )
    
    # Write output
    with open(args.output, 'w', encoding='utf-8') as f:
        f.write(html)
    
    print(f"✅ Report generated: {args.output}")
    print(f"   {len(all_items)} total items ({total_prs} PRs, {total_issues} issues)")
    print(f"   {len(contributors)} contributors")
    print(f"   {len(repos)} repositories")


if __name__ == '__main__':
    main()
