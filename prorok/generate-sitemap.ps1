$today = Get-Date -Format "yyyy-MM-dd"
$csvPath = "seo-pages.csv"
$outputPath = "sitemap.xml"

$lines = Get-Content $csvPath
$urls = @()

foreach ($line in $lines) {
    if ($line -match '^\s*$' -or $line -match '^@" | "^"@ | ^"@ | @\| ') { continue }
    if ($line -match '^[a-z0-9_]+\.html,') {
        $parts = $line -split ','
        $urls += $parts[0]
    }
}

$urls += 'index.html'

$xml = '<?xml version="1.0" encoding="UTF-8"?>'
$xml += '<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">'

foreach ($url in $urls) {
    $xml += "  <url>`n"
    $xml += "    <loc>https://prorok.site/$url</loc>`n"
    $xml += "    <lastmod>$today</lastmod>`n"
    $xml += "  </url>`n"
}

$xml += '</urlset>'

Set-Content -Path $outputPath -Value $xml -Encoding UTF8