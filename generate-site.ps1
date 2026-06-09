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
               aria-label="Открыть бота Спроси Пророка в Telegram">

                <img src="/prorok/assets/img/bot-avatar.svg"
                     alt="Библейский бот"
                     class="bot-avatar"
                     width="64" height="64"
                     loading="eager" decoding="async">

                <span class="bot-text">
                    <strong>Получите цитаты из Библии для вашей ситуации</strong><br>
                    Откройте бота «Спроси Пророка» в Telegram — поиск по Библии без AI-генерации.
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
                       -replace '\{\{CONTENT\}\}', $contentHtml `
                       -replace '\{\{BACK_LINK\}\}', $backLink

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
            if ($line -match '^backLink:\s*(.+)') { $backLink = $Matches[1].Trim().Trim('"', "'") }
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

    if (-not $backLink) {
        if ($slug -match '^christianity/') { $backLink = '/prorok/christianity/index.html' }
        elseif ($slug -match '^judaism/') { $backLink = '/prorok/judaism/index.html' }
        elseif ($slug -match '^islam/') { $backLink = '/prorok/islam/index.html' }
        else { $backLink = '/prorok/index.html' }
    }

    $contentHtml = Convert-MarkdownToHtml -md $mdBody
    $plainContent = ($contentHtml -replace '<[^>]+>', ' ' -replace '\s+', ' ').Trim()

    $allUrls += $canonical
    $allSlugs += $slug
    $allMeta[$slug] = @{ title = $title; desc = $description; content = $plainContent }

    New-ArticlePage -slug $slug -title $title -description $description -contentHtml $contentHtml -canonical $canonical
    $pagesGenerated++
}

# Religion section pages
$religionPages = @(
    @{ slug = "christianity/index.html"; template = "christianity.html"; title = "Христианство"; desc = "Христианство: вера в Иисуса Христа, любовь, прощение и вечная жизнь."; canonical = "https://prorok.site/christianity/index.html" },
    @{ slug = "judaism/index.html"; template = "judaism.html"; title = "Иудаизм"; desc = "Иудаизм: древняя традиция, монотеизм, Тора и мудрость пророков."; canonical = "https://prorok.site/judaism/index.html" },
    @{ slug = "islam/index.html"; template = "islam.html"; title = "Ислам"; desc = "Ислам: вторая по численности религия мира, основанная на Коране."; canonical = "https://prorok.site/islam/index.html" }
)

foreach ($rp in $religionPages) {
    $tplPath = Join-Path $templatesDir $rp.template
    if (-not (Test-Path $tplPath)) { continue }
    $tpl = Get-Content $tplPath -Raw -Encoding UTF8
    $safeTitle = [System.Security.SecurityElement]::Escape($rp.title)
    $safeDesc = [System.Security.SecurityElement]::Escape($rp.desc)
    $safeCanonical = [System.Security.SecurityElement]::Escape($rp.canonical)
    $pageHtml = $tpl -replace '\{\{TITLE\}\}', $safeTitle `
                   -replace '\{\{DESCRIPTION\}\}', $safeDesc `
                   -replace '\{\{CANONICAL\}\}', $safeCanonical `
                   -replace '\{\{GA_TAG\}\}', $gaTag `
                   -replace '\{\{BOT_BOX\}\}', $botBox `
                   -replace '\{\{YEAR\}\}', $script:year
    $outDir = Join-Path $outputDir (Split-Path $rp.slug -Parent)
    New-Item -Path $outDir -ItemType Directory -Force | Out-Null
    [System.IO.File]::WriteAllText((Join-Path $outputDir $rp.slug), $pageHtml, [System.Text.UTF8Encoding]::new($false))
    $allUrls += $rp.canonical
    $allSlugs += $rp.slug
    Write-Host "  Generated: $($rp.slug)"
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
    <p>Сайт о христианстве и Библии. Найдите ответы на важные вопросы веры.</p>
    <h3>Популярные темы</h3>
    <ul>
$popularList
    </ul>
"@

$indexTemplatePath = Join-Path $templatesDir "landing.html"
$indexTemplate = Get-Content $indexTemplatePath -Raw -Encoding UTF8

$indexHtml = $indexTemplate -replace '\{\{GA_TAG\}\}', $gaTag `
                          -replace '\{\{BOT_BOX\}\}', $botBox `
                          -replace '\{\{YEAR\}\}', $script:year

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
