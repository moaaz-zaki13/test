#!/bin/bash
# .github/scripts/create-dashboard.sh

create_dashboard() {
    echo "Creating unified dashboard..."
    
    cat > index.html << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title> CI/CD Reports Dashboard</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; background: #f5f5f5; }
        .dashboard { max-width: 1200px; margin: 0 auto; }
        .header { background: white; padding: 20px; border-radius: 10px; margin-bottom: 20px; box-shadow: 0 2px 5px rgba(0,0,0,0.1); }
        .section { background: white; padding: 20px; border-radius: 10px; margin-bottom: 20px; box-shadow: 0 2px 5px rgba(0,0,0,0.1); }
        pre { background: #f8f8f8; padding: 15px; border-radius: 5px; overflow-x: auto; white-space: pre-wrap; }
        .file-list { list-style: none; padding: 0; }
        .file-list li { margin: 5px 0; }
        .file-list a { color: #0366d6; text-decoration: none; }
        .file-list a:hover { text-decoration: underline; }
        .success { color: #28a745; }
        .warning { color: #ffc107; }
        .error { color: #dc3545; }
        .info { color: #17a2b8; }
    </style>
</head>
<body>
    <div class="dashboard">
        <div class="header">
            <h1> CI/CD Reports Dashboard</h1>
            
EOF

    add_unit_test_section
    add_eslint_section
    add_codeql_section
    add_trivy_section
    
    cat >> index.html << 'EOF'
    </div>
</body>
</html>
EOF

    echo "Dashboard created at index.html"
}

add_unit_test_section() {
    echo "<div class='section'>" >> index.html
    echo "<h2> Unit Tests</h2>" >> index.html
    echo "<h3>Test Results by Node Version</h3>" >> index.html
    
    found_tests=false
    for dir in all-reports/test-results-*; do
        if [ -d "$dir" ]; then
            found_tests=true
            node_version=$(basename "$dir" | sed 's/test-results-//')
            echo "<h4>Node.js $node_version</h4>" >> index.html
            echo "<ul class='file-list'>" >> index.html
            
            # Find and link to test result files
            find "$dir" -type f \( -name "*.json" -o -name "*.html" \) | while read file; do
                filename=$(basename "$file")
                if [[ "$filename" == *"index.html"* && "$file" == *"coverage"* ]]; then
                    echo "<li> <a href=\"$file\" target=\"_blank\">Coverage Report</a> (Interactive)</li>" >> index.html
                elif [[ "$filename" == *".json"* ]]; then
                    echo "<li> <a href=\"$file\" target=\"_blank\">Test Results JSON</a>" >> index.html
                    
                    # Show test summary if jq is available
                    if command -v jq &> /dev/null; then
                        stats=$(jq -r '" - Tests: \(.numPassedTests)/\(.numTotalTests) passed, Failures: \(.numFailedTests)"' "$file" 2>/dev/null)
                        if [ $? -eq 0 ]; then
                            echo " $stats" >> index.html
                        fi
                    fi
                    echo "</li>" >> index.html
                else
                    echo "<li><a href=\"$file\" target=\"_blank\">$filename</a></li>" >> index.html
                fi
            done
            echo "</ul>" >> index.html
        fi
    done
    
    if [ "$found_tests" = false ]; then
        echo "<p>No test results found</p>" >> index.html
    fi
    echo "</div>" >> index.html
}

add_eslint_section() {
    echo "<div class='section'>" >> index.html
    echo "<h2> ESLint Analysis</h2>" >> index.html
    if [ -f "all-reports/eslint-report/eslint-report.json" ]; then
        echo "<h3> ESLint Issues Found</h3>" >> index.html
        
        # Parse ESLint JSON and show actual issues
        if command -v jq &> /dev/null; then
            issues_count=$(jq -r 'if type == "array" then [.[].messages[]] | length else [.messages[]] | length end' all-reports/eslint-report/eslint-report.json 2>/dev/null || echo "0")
            
            if [ "$issues_count" -gt 0 ]; then
                echo "<p><span class='warning'> Found $issues_count linting issues:</span></p>" >> index.html
                echo "<pre>" >> index.html
                
                jq -r '
                    if . | type == "array" then 
                        .[] | 
                        " File: \(.filePath)\n" +
                        (.messages[] | "   Line \(.line):\(.column) - \(.message) \n     Rule: \(.ruleId)\n") +
                        "---"
                    else 
                        " File: \(.filePath)\n" +
                        (.messages[] | "   Line \(.line):\(.column) - \(.message) \n     Rule: \(.ruleId)\n") +
                        "---"
                    end
                ' all-reports/eslint-report/eslint-report.json 2>/dev/null >> index.html
                
                echo "</pre>" >> index.html
            else
                echo "<p><span class='success'> No linting issues found!</span></p>" >> index.html
            fi
        else
            echo "<pre> ESLint report generated. Install jq for detailed issue display.</pre>" >> index.html
        fi
        
        echo "<p><a href=\"all-reports/eslint-report/eslint-report.json\" target=\"_blank\"> View Full JSON Report</a></p>" >> index.html
    else
        echo "<p> No ESLint report found</p>" >> index.html
    fi
    echo "</div>" >> index.html
}

add_codeql_section() {
    echo "<div class='section'>" >> index.html
    echo "<h2> CodeQL Security Scan</h2>" >> index.html
    if [ -d "all-reports/codeql-results" ]; then
        echo "<h3> Security Findings</h3>" >> index.html
        
        found_results=false
        for result_file in all-reports/codeql-results/*.sarif all-reports/codeql-results/*.json; do
            if [ -f "$result_file" ]; then
                found_results=true
                echo "<h4> $(basename "$result_file")</h4>" >> index.html
                
                if command -v jq &> /dev/null; then
                    findings_count=$(jq -r '.runs[0].results | length' "$result_file" 2>/dev/null || echo "0")
                    
                    if [ "$findings_count" -gt 0 ] && [ "$findings_count" != "null" ]; then
                        echo "<p><span class='warning'> Found $findings_count security findings:</span></p>" >> index.html
                        echo "<pre>" >> index.html
                        
                        jq -r '
                            .runs[0].results[]? | 
                            " \(.level? // "MEDIUM"): \(.ruleId)\n" +
                            "    \(.message.text)\n" +
                            "    \(.locations[0].physicalLocation.artifactLocation.uri? // "Unknown file"):\(.locations[0].physicalLocation.region.startLine? // "?")\n" +
                            "---"
                        ' "$result_file" 2>/dev/null >> index.html
                        
                        echo "</pre>" >> index.html
                    else
                        echo "<p><span class='success'>No security issues found!</span></p>" >> index.html
                    fi
                else
                    echo "<pre> Security scan completed. View full report for details.</pre>" >> index.html
                fi
            fi
        done
        
        if [ "$found_results" = false ]; then
            echo "<p> Security analysis completed. No issues reported.</p>" >> index.html
        fi
        
        echo "<p><a href=\"all-reports/codeql-results/\" target=\"_blank\"> View Full Security Reports</a></p>" >> index.html
    else
        echo "<p> No CodeQL results found</p>" >> index.html
    fi
    echo "</div>" >> index.html
}

add_trivy_section() {
    echo "<div class='section'>" >> index.html
    echo "<h2> Trivy Vulnerability Scan</h2>" >> index.html
    
    # File System Scan
    if [ -f "all-reports/trivy-reports/trivy-fs-report.txt" ]; then
        echo "<h3> File System Scan</h3>" >> index.html
        echo "<pre>" >> index.html
        echo "=== File System Vulnerabilities ===" >> index.html
        # Show the beginning of the report (usually contains summary)
        head -30 all-reports/trivy-reports/trivy-fs-report.txt >> index.html
        echo "</pre>" >> index.html
        echo "<p><a href=\"all-reports/trivy-reports/trivy-fs-report.txt\" target=\"_blank\"> View Full File System Report</a></p>" >> index.html
    else
        echo "<p> No Trivy file system scan found</p>" >> index.html
    fi
    
    # Container Image Scan
    if [ -f "all-reports/trivy-reports/trivy-image-report.txt" ]; then
        echo "<h3>🐋 Container Image Scan</h3>" >> index.html
        echo "<pre>" >> index.html
        echo "=== Container Image Vulnerabilities ===" >> index.html
        head -30 all-reports/trivy-reports/trivy-image-report.txt >> index.html
        echo "</pre>" >> index.html
        echo "<p><a href=\"all-reports/trivy-reports/trivy-image-report.txt\" target=\"_blank\"> View Full Image Scan Report</a></p>" >> index.html
    else
        echo "<p>No Trivy image scan found (optional scan)</p>" >> index.html
    fi
    
    echo "</div>" >> index.html
}

# Main execution
create_dashboard