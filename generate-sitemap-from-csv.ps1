#requires -Version 5.1
$ErrorActionPreference = 'SilentlyContinue'
$ProgressPreference = 'SilentlyContinue'

$script:today = Get-Date -Format "yyyy-MM-dd"
$root = $PSScriptRoot
$csvPath = Join-Path $root "seo-pages.csv"
$outputPath = Join-Path $root "prorok\sitemap.xml"
$baseUrl = "https://prorok.site"

if (-not (Test-Path $csvPath)) {
    Write-Host "ERROR: seo-pages.csv not found at $csvPath"
    exit 1
}

$lines = Get-Content $csvPath -Encoding UTF8
$urls = @()

foreach ($line in $lines) {
    if ($line -match '^\s*$' -or $line -match '^@" | "^"@ | ^"@ | @\| ') { continue }
    if ($line -match '^file,') { continue }
    if ($line -match '^[a-z0-9_\-]+\.html,') {
        $parts = $line -split ','
        $slug = $parts[0].Trim('"')
        $urls += "$baseUrl/$slug"
    }
}

$urls += "$baseUrl/index.html"
$sorted = $urls | Sort-Object -Unique

$xml = "<?xml version=`"1.0`" encoding=`"UTF-8`"?>`n"
$xml += "<urlset xmlns=`"http://www.sitemaps.org/schemas/sitemap/0.9`">`n"

foreach ($url in $sorted) {
    $xml += "  <url>`n"
    $xml += "    <loc>$url</loc>`n"
    $xml += "    <lastmod>$script:today</lastmod>`n"
    $xml += "    <changefreq>weekly</changefreq>`n"
    $xml += "    <priority>0.8</priority>`n"
    $xml += "  </url>`n"
}

$xml += "</urlset>"

$tempPath = [System.IO.Path]::GetTempFileName()
Set-Content -Path $tempPath -Value $xml -Encoding UTF8
Copy-Item $tempPath $outputPath -Force
Remove-Item $tempPath

Write-Host "Sitemap generated: $outputPath"
Write-Host "Total URLs: $($sorted.Count)"
Write-Host "Date: $script:today"
