#requires -Version 5.1
$ErrorActionPreference = 'SilentlyContinue'
$ProgressPreference = 'SilentlyContinue'

$script:today = Get-Date -Format "yyyy-MM-dd"
$script:year = Get-Date -Year

$root = $PSScriptRoot
$articlesDir = Join-Path $root "articles"
$templatesDir = Join-Path $root "templates"
$outputDir = Join-Path $root "prorok"

if (-not (Test-Path $articlesDir)) {
    Write-Host "ERROR: articles/ folder not found at $articlesDir"
    exit 1
}
if (-not (Test-Path $templatesDir)) {
    Write-Host "ERROR: templates/ folder not found at $templatesDir"
    exit 1
}

New-Item -Path $outputDir -ItemType Directory -Force | Out-Null

$gaTag = @"
    <!-- Google tag (gtag.js) -->
    <script async src="https://www.googletagmanager.com/gtag/js?id=G-D2LRQM94EG"></script>
    <script>
      window.dataLayer = window.dataLayer || [];
      function gtag(){dataLayer.push(arguments);}
      gtag('js', new Date());
      gtag('config', 'G-D2LRQM94EG');
    </script>
"@

$botBox = @"
        <div class="bot-box">
            <a href="https://t.me/SprosiProroka_bot"
               class="bot-link js-telegram-cta"
               data-cta="article-inline"
               data-section="bottom"
               aria-label="Open Sprosi Proroka bot in Telegram">

                <img src="/prorok/assets/img/bot-avatar.svg"
                     alt="Sprosi Proroka bot"
                     class="bot-avatar"
                     width="64" height="64"
                     loading="eager" decoding="async">

                <span class="bot-text">
                    <strong>Get Bible quotes for your situation</strong><br>
                    Open the Sprosi Proroka bot in Telegram.
                </span>
            </a>
        </div>
"@

function Convert-MarkdownToHtml {
    param([string]$md)
    $lines = $md -split "`n"
    $htmlLines = @()
    $inList = $false
    $inBlockquote = $false
    $listBuffer = @()
    $bqBuffer = @()
    $skipFirstH1 = $true

    foreach ($line in $lines) {
        $trimmed = $line.Trim()

        if ($trimmed -eq '') {
            if ($inList) {
                $items = $listBuffer | ForEach-Object { $t = $_ -replace '^- ', ''; "      <li>$t</li>" }
                $htmlLines += "    <ul>"
                $htmlLines += $items
                $htmlLines += "    </ul>"
                $inList = $false
                $listBuffer = @()
            }
            if ($inBlockquote) {
                $text = ($bqBuffer -join ' ') -replace '^(> )+', ''
                $text = $text.Trim()
                $htmlLines += "    <blockquote><p>$text</p></blockquote>"
                $inBlockquote = $false
                $bqBuffer = @()
            }
            continue
        }

        if ($trimmed -match '^>') {
            if ($inList) {
                $items = $listBuffer | ForEach-Object { $t = $_ -replace '^- ', ''; "      <li>$t</li>" }
                $htmlLines += "    <ul>"
                $htmlLines += $items
                $htmlLines += "    </ul>"
                $inList = $false
                $listBuffer = @()
            }
            $inBlockquote = $true
            $bqBuffer += $trimmed
            continue
        }

        if ($inBlockquote) {
            $text = ($bqBuffer -join ' ') -replace '^(> )+', ''
            $text = $text.Trim()
            $htmlLines += "    <blockquote><p>$text</p></blockquote>"
            $inBlockquote = $false
            $bqBuffer = @()
        }

        if ($trimmed -match '^- ') {
            if (-not $inList) { $inList = $true }
            $listBuffer += $trimmed
            continue
        }

        if ($inList) {
            $items = $listBuffer | ForEach-Object { $t = $_ -replace '^- ', ''; "      <li>$t</li>" }
            $htmlLines += "    <ul>"
            $htmlLines += $items
            $htmlLines += "    </ul>"
            $inList = $false
            $listBuffer = @()
        }

        if ($trimmed -match '^### (.+)') {
            $htmlLines += "    <h3>$($Matches[1])</h3>"
            continue
        }
        if ($trimmed -match '^## (.+)') {
            $htmlLines += "    <h3>$($Matches[1])</h3>"
            continue
        }
        if ($trimmed -match '^# (.+)') {
            if ($skipFirstH1) { $skipFirstH1 = $false; continue }
            $htmlLines += "    <h2>$($Matches[1])</h2>"
            continue
        }

        if ($trimmed -match '^\d+\.\s+(.+)') {
            $rawText = $Matches[1] -replace '\*\*(.+?)\*\*', '$1' -replace '\*(.+?)\*', '$1'
            $htmlLines += "    <p><strong>$rawText</strong></p>"
            continue
        }

        $text = $trimmed
        $text = $text -replace '\*\*(.+?)\*\*', '<strong>$1</strong>'
        $text = $text -replace '\*(.+?)\*', '<em>$1</em>'
        $htmlLines += "    <p>$text</p>"
    }

    if ($inList) {
        $items = $listBuffer | ForEach-Object { $t = $_ -replace '^- ', ''; "      <li>$t</li>" }
        $htmlLines += "    <ul>"
        $htmlLines += $items
        $htmlLines += "    </ul>"
    }
    if ($inBlockquote) {
        $text = ($bqBuffer -join ' ') -replace '^(> )+', ''
        $text = $text.Trim()
        $htmlLines += "    <blockquote><p>$text</p></blockquote>"
    }

    return $htmlLines -join "`n"
}

function New-ArticlePage {
    param(
        [string]$slug,
        [string]$title,
        [string]$description,
        [string]$contentHtml,
        [string]$canonical
    )

    $templatePath = Join-Path $templatesDir "article.html"
    $template = Get-Content $templatePath -Raw -Encoding UTF8

    $safeTitle = [System.Security.SecurityElement]::Escape($title)
    $safeDesc = [System.Security.SecurityElement]::Escape($description)
    $safeCanonical = [System.Security.SecurityElement]::Escape($canonical)

    $pageHtml = $template -replace '\{\{TITLE\}\}', $safeTitle `
                       -replace '\{\{DESCRIPTION\}\}', $safeDesc `
                       -replace '\{\{CANONICAL\}\}', $safeCanonical `
                       -replace '\{\{GA_TAG\}\}', $gaTag `
                       -replace '\{\{BOT_BOX\}\}', $botBox `
                       -replace '\{\{YEAR\}\}', $script:year `
                       -replace '\{\{CONTENT\}\}', $contentHtml

    $relDir = Split-Path $slug -Parent
    if ($relDir) {
        $outDir = Join-Path $outputDir $relDir
        New-Item -Path $outDir -ItemType Directory -Force | Out-Null
    }

    $outPath = Join-Path $outputDir $slug
    [System.IO.File]::WriteAllText($outPath, $pageHtml, [System.Text.UTF8Encoding]::new($false))
    Write-Host "  Generated: $slug"
    return $slug
}

function New-Sitemap {
    param([string[]]$urls)
    $sitemapPath = Join-Path $outputDir "sitemap.xml"
    $tempPath = [System.IO.Path]::GetTempFileName()
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

    Set-Content -Path $tempPath -Value $xml -Encoding UTF8
    Copy-Item $tempPath $sitemapPath -Force
    Remove-Item $tempPath
    Write-Host "Sitemap: $sitemapPath ($($sorted.Count) URLs)"
}

function New-SearchIndex {
    param(
        [string[]]$slugs,
        [hashtable]$meta
    )
    $indexPath = Join-Path $outputDir "search-index.json"
    $entries = @()
    foreach ($slug in $slugs) {
        if ($meta.ContainsKey($slug)) {
            $m = $meta[$slug]
            $entries += [PSCustomObject]@{
                url     = "/prorok/$slug"
                title   = $m.title
                desc    = $m.desc
                content = $m.content
            }
        }
    }
    $json = $entries | ConvertTo-Json -Depth 3 -Compress
    [System.IO.File]::WriteAllText($indexPath, $json, [System.Text.UTF8Encoding]::new($false))
    Write-Host "Search index: $indexPath ($($entries.Count) entries)"
}

# === MAIN ===

$mdFiles = Get-ChildItem -Path $articlesDir -Filter *.md -Recurse | Sort-Object FullName

if ($mdFiles.Count -eq 0) {
    Write-Host "No .md files found in $articlesDir"
    exit 1
}

$allUrls = @()
$allSlugs = @()
$allMeta = @{}
$pagesGenerated = 0

Write-Host "=== Prorok Site Generator ==="
Write-Host "Articles found: $($mdFiles.Count)"
Write-Host ""

foreach ($mdFile in $mdFiles) {
    $content = Get-Content $mdFile.FullName -Raw -Encoding UTF8

    $title = ""
    $description = ""
    $canonical = ""
    $mdBody = ""

    if ($content -match '(?s)^---\s*\r?\n(.+?)\r?\n---\s*\r?\n(.*)$') {
        $frontmatter = $Matches[1]
        $mdBody = $Matches[2]

        foreach ($line in ($frontmatter -split "`r?`n")) {
            $line = $line.Trim()
            if ($line -match '^title:\s*(.+)') { $title = $Matches[1].Trim().Trim('"', "'") }
            if ($line -match '^description:\s*(.+)') { $description = $Matches[1].Trim().Trim('"', "'") }
            if ($line -match '^canonical:\s*(.+)') { $canonical = $Matches[1].Trim().Trim('"', "'") }
        }
    } else {
        $mdBody = $content
    }

    if (-not $title) {
        $title = [System.IO.Path]::GetFileNameWithoutExtension($mdFile.Name)
    }
    if (-not $description) {
        $description = $title
    }

    $slug = $mdFile.FullName.Substring($articlesDir.Length + 1)
    $slug = $slug -replace '\.md$', '.html'

    if (-not $canonical) {
        $canonical = "https://prorok.site/$slug"
    }

    $contentHtml = Convert-MarkdownToHtml -md $mdBody
    $plainContent = ($contentHtml -replace '<[^>]+>', ' ' -replace '\s+', ' ').Trim()

    $allUrls += $canonical
    $allSlugs += $slug
    $allMeta[$slug] = @{ title = $title; desc = $description; content = $plainContent }

    New-ArticlePage -slug $slug -title $title -description $description -contentHtml $contentHtml -canonical $canonical
    $pagesGenerated++
}

# Homepage
$indexSlug = "index.html"
$indexCanonical = "https://prorok.site/index.html"

$popularItems = @()
$count = 0
$sortedKeys = @($allMeta.Keys) | Sort-Object
foreach ($key in $sortedKeys) {
    if ($count -ge 12) { break }
    $m = $allMeta[$key]
    $popularItems += "        <li><a href=""/prorok/$key"">$($m.title)</a></li>"
    $count++
}
$popularList = $popularItems -join "`n"

$homeContent = @"
    <p>Site about Christianity and the Bible. Find answers to important questions of faith.</p>
    <h3>Popular topics</h3>
    <ul>
$popularList
    </ul>
"@

$indexTemplatePath = Join-Path $templatesDir "article.html"
$indexTemplate = Get-Content $indexTemplatePath -Raw -Encoding UTF8

$indexHtml = $indexTemplate -replace '\{\{TITLE\}\}', 'Prorok' `
                          -replace '\{\{DESCRIPTION\}\}', 'Christianity, Bible, faith, hope, love.' `
                          -replace '\{\{CANONICAL\}\}', $indexCanonical `
                          -replace '\{\{GA_TAG\}\}', $gaTag `
                          -replace '\{\{BOT_BOX\}\}', $botBox `
                          -replace '\{\{YEAR\}\}', $script:year `
                          -replace '\{\{CONTENT\}\}', $homeContent

[System.IO.File]::WriteAllText((Join-Path $outputDir $indexSlug), $indexHtml, [System.Text.UTF8Encoding]::new($false))
Write-Host "  Generated: $indexSlug"
$allUrls += $indexCanonical
$allSlugs += $indexSlug

Write-Host ""
Write-Host "=== Summary ==="
Write-Host "Pages generated: $pagesGenerated (+ 1 homepage)"

New-Sitemap -urls $allUrls
New-SearchIndex -slugs $allSlugs -meta $allMeta

Write-Host ""
Write-Host "Done."
Write-Host "Output: $outputDir"
