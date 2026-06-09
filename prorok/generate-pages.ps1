$ErrorActionPreference = 'SilentlyContinue'
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$csvPath = Join-Path $root "seo-pages.csv"

if (-not (Test-Path $csvPath)) {
    Write-Host "seo-pages.csv not found at $csvPath"
    exit 1
}

$lines = Get-Content $csvPath -Encoding UTF8

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
                     alt="Спроси Пророка — бот в Telegram"
                     class="bot-avatar"
                     width="64" height="64"
                     loading="eager" decoding="async">

                <span class="bot-text">
                    <strong>Получить подборку цитат по вашей ситуации</strong><br>
                    Откройте бота «Спроси Пророка» в Telegram — поиск по Библии без AI-генерации.
                </span>
            </a>
        </div>
"@

$scriptBlock = {
    param($slug, $title, $description)

    $relDir = Split-Path $slug -Parent
    if ($relDir) { $null = New-Item -ItemType Directory -Path (Join-Path $root $relDir) -Force }

    $html = @"
<!DOCTYPE html>
<html lang="ru">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>$title — Пророк</title>
    <meta name="description" content="$description">
    <link rel="canonical" href="https://prorok.site/prorok/$slug">
    <link rel="stylesheet" href="/prorok/assets/css/style.css">
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Cinzel:wght@400;700&family=Inter:wght@300;400;600&display=swap" rel="stylesheet">
$gaTag
</head>
<body>
    <header>
        <h1>Пророк</h1>
    </header>
    <nav>
        <ul>
            <li><a href="/prorok/index.html">Главная</a></li>
            <li><a href="/prorok/christianity/index.html">Христианство</a></li>
            <li><a href="/prorok/blog/index.html">Блог</a></li>
            <li><a href="/prorok/search/index.html">Поиск</a></li>
        </ul>
    </nav>
    <main>
        <article>
            <h2>$title</h2>
            <p>$description</p>
        </article>
$botBox
    </main>
    <footer>
        <p>&copy; 2026 Пророк. Все права защищены.</p>
    </footer>
    <script src="/prorok/assets/js/main.js"></script>
</body>
</html>
"@

    $outPath = Join-Path $root $slug
    Set-Content -Path $outPath -Value $html -Encoding UTF8
    Write-Host "Generated: $slug"
}

$count = 0
foreach ($line in $lines) {
    if ($line -match '^\s*$' -or $line -match '^@" | "^"@ | ^"@ | @\| ') { continue }
    if ($line -match '^file,') { continue }

    $parts = $line -split ','
    if ($parts.Count -lt 3) { continue }

    $file = $parts[0].Trim('"')
    $title = $parts[1].Trim('"')
    $description = $parts[2].Trim('"')

    if ($file -match '\.html$') {
        & $scriptBlock $file $title $description
        $count++
    }
}

# Also generate index.html
$indexHtml = @"
<!DOCTYPE html>
<html lang="ru">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Пророк — Библия и христианство</title>
    <meta name="description" content="Сайт о христианстве и Библии. Найдите ответы на важные вопросы веры.">
    <link rel="canonical" href="https://prorok.site/prorok/index.html">
    <link rel="stylesheet" href="/prorok/assets/css/style.css">
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Cinzel:wght@400;700&family=Inter:wght@300;400;600&display=swap" rel="stylesheet">
$gaTag
</head>
<body>
    <header>
        <h1>Пророк</h1>
    </header>
    <nav>
        <ul>
            <li><a href="/prorok/index.html">Главная</a></li>
            <li><a href="/prorok/christianity/index.html">Христианство</a></li>
            <li><a href="/prorok/blog/index.html">Блог</a></li>
            <li><a href="/prorok/search/index.html">Поиск</a></li>
        </ul>
    </nav>
    <main>
        <article>
            <h2>Добро пожаловать на Пророк</h2>
            <p>Сайт о христианстве и Библии. Найдите ответы на важные вопросы веры.</p>
        </article>
$botBox
    </main>
    <footer>
        <p>&copy; 2026 Пророк. Все права защищены.</p>
    </footer>
    <script src="/prorok/assets/js/main.js"></script>
</body>
</html>
"@
Set-Content -Path (Join-Path $root "index.html") -Value $indexHtml -Encoding UTF8
Write-Host "Generated: index.html"
$count++

Write-Host ""
Write-Host "Done. Total pages generated: $count"
