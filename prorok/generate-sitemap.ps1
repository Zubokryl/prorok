$today = Get-Date -Format "yyyy-MM-dd"
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$outputPath = Join-Path $root "sitemap.xml"
$tempPath = [System.IO.Path]::GetTempFileName()

$allHtml = Get-ChildItem -Path $root -Recurse -Filter *.html -ErrorAction SilentlyContinue | Where-Object { $_.FullName -notlike '*.git*' }

$urls = @{}
foreach ($f in $allHtml) {
    $rel = $f.FullName.Substring($root.Length + 1).Replace('\', '/')
    $size = $f.Length
    if ($urls.ContainsKey($rel)) {
        if ($size -gt $urls[$rel].Length) { $urls[$rel] = $f }
    } else {
        $urls[$rel] = $f
    }
}

$sorted = $urls.Keys | Sort-Object

$xml = "<?xml version=`"1.0`" encoding=`"UTF-8`"?>`n"
$xml += "<urlset xmlns=`"http://www.sitemaps.org/schemas/sitemap/0.9`">`n"

foreach ($rel in $sorted) {
    $url = "https://prorok.site/$rel"
    $xml += "  <url>`n"
    $xml += "    <loc>$url</loc>`n"
    $xml += "    <lastmod>$today</lastmod>`n"
    $xml += "    <changefreq>weekly</changefreq>`n"
    $xml += "    <priority>0.8</priority>`n"
    $xml += "  </url>`n"
}

$xml += "</urlset>"

Set-Content -Path $tempPath -Value $xml -Encoding UTF8
Copy-Item $tempPath $outputPath -Force
Remove-Item $tempPath

Write-Host "Sitemap generated: $outputPath"
Write-Host "Total URLs: $($sorted.Count)"
Write-Host "Date: $today"
