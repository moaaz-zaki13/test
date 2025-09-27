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
        pre { background: #f8f8f8; padding: 15px; border-radius: 5px; overflow-x: auto; }
        .file-list { list-style: none; padding: 0; }
        .file-list li { margin: 5px 0; }
        .file-list a { color: #0366d6; text-decoration: none; }
        .file-list a:hover { text-decoration: underline; }
    </style>
</head>
<body>
    <div class="dashboard">
        <div class="header">
            <h1> CI/CD Reports Dashboard</h1>
            <p>Generated on: $(date)</p>
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

    echo " Dashboard created at index.html"
}

add_unit_test_section() {
    echo "<div class='section'>" >> index.html
    echo "<h2> Unit Tests</h2>" >> index.html
    echo "<h3>Test Results by Node Version</h3>" >> index.html
    echo "<ul class='file-list'>" >> index.html
    
    # Look for test-results-18.x and test-results-20.x directories
    for dir in all-reports/test-results-*; do
        if [ -d "$dir" ]; then
            node_version=$(basename "$dir" | sed 's/test-results-//')
            echo "<li><strong>Node.js $node_version</strong></li>" >> index.html
            find "$dir" -type f \( -name "*.json" -o -name "*.html" \) | while read file; do
                filename=$(basename "$file")
                echo "<li><a href=\"$file\" target=\"_blank\">$filename</a></li>" >> index.html
            done
        fi
    done
    
    echo "</ul>" >> index.html
    echo "</div>" >> index.html
}

add_eslint_section() {
    echo "<div class='section'>" >> index.html
    echo "<h2> ESLint Analysis</h2>" >> index.html
    if [ -f "all-reports/eslint-report/eslint-report.json" ]; then
        echo "<h3>ESLint Report</h3>" >> index.html
        echo "<pre>ESLint report available - view full report for details</pre>" >> index.html
        echo "<p><a href=\"all-reports/eslint-report/eslint-report.json\" target=\"_blank\">View Full JSON Report</a></p>" >> index.html
    else
        echo "<p>No ESLint report found</p>" >> index.html
    fi
    echo "</div>" >> index.html
}

add_codeql_section() {
    echo "<div class='section'>" >> index.html
    echo "<h2> CodeQL Security Scan</h2>" >> index.html
    if [ -d "all-reports/codeql-results" ]; then
        echo "<h3>Security Findings</h3>" >> index.html
        echo "<ul class='file-list'>" >> index.html
        find all-reports/codeql-results -type f \( -name "*.sarif" -o -name "*.json" \) | while read file; do
            filename=$(basename "$file")
            echo "<li><a href=\"$file\" target=\"_blank\">$filename</a></li>" >> index.html
        done
        echo "</ul>" >> index.html
    else
        echo "<p>No CodeQL results found</p>" >> index.html
    fi
    echo "</div>" >> index.html
}

add_trivy_section() {
    echo "<div class='section'>" >> index.html
    echo "<h2> Trivy Vulnerability Scan</h2>" >> index.html
    
    # File System Scan
    if [ -f "all-reports/trivy-reports/trivy-fs-report.txt" ]; then
        echo "<h3>File System Scan</h3>" >> index.html
        echo "<pre>" >> index.html
        cat all-reports/trivy-reports/trivy-fs-report.txt | head -20 >> index.html
        echo "</pre>" >> index.html
        echo "<p><a href=\"all-reports/trivy-reports/trivy-fs-report.txt\" target=\"_blank\">View Full Report</a></p>" >> index.html
    else
        echo "<p>No Trivy file system scan found</p>" >> index.html
    fi
    
    # Container Image Scan
    if [ -f "all-reports/trivy-reports/trivy-image-report.txt" ]; then
        echo "<h3>Container Image Scan</h3>" >> index.html
        echo "<pre>" >> index.html
        cat all-reports/trivy-reports/trivy-image-report.txt | head -20 >> index.html
        echo "</pre>" >> index.html
        echo "<p><a href=\"all-reports/trivy-reports/trivy-image-report.txt\" target=\"_blank\">View Full Report</a></p>" >> index.html
    else
        echo "<p>No Trivy image scan found</p>" >> index.html
    fi
    
    echo "</div>" >> index.html
}

# Main execution
create_dashboard