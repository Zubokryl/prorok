#requires -Version 5.1
$ErrorActionPreference = 'SilentlyContinue'
$ProgressPreference = 'SilentlyContinue'

$today = Get-Date -Format "yyyy-MM-dd"
$year = (Get-Date).Year

$root = $PSScriptRoot
$articlesDir = Join-Path $root "articles"
$templatesDir = Join-Path $root "templates"
$outputDir = Join-Path $root "prorok"
$csvPath = Join-Path $root "seo-pages.csv"
$baseUrl = "https://prorok.site"

if (-not (Test-Path $templatesDir)) {
    Write-Host "ERROR: templates/ folder not found at $templatesDir"
    exit 1
}
if (-not (Test-Path $articlesDir)) {
    New-Item -Path $articlesDir -ItemType Directory -Force | Out-Null
}

New-Item -Path $outputDir -ItemType Directory -Force | Out-Null

# Copy assets (CSS, JS, images) into output folder
$assetsSrc = Join-Path $root "assets"
$assetsDst = Join-Path $outputDir "assets"
if (Test-Path $assetsSrc) {
    if (-not (Test-Path $assetsDst)) {
        New-Item -Path $assetsDst -ItemType Directory -Force | Out-Null
    }
    Copy-Item -Path "$assetsSrc\*" -Destination $assetsDst -Recurse -Force
}

# Create .nojekyll to prevent Jekyll processing on GitHub Pages
[System.IO.File]::WriteAllText((Join-Path $outputDir ".nojekyll"), "", [System.Text.UTF8Encoding]::new($false))

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

                <img src="/prorok/assets/images/book.png"
                     alt="Библейский бот"
                     class="bot-avatar"
                     width="64" height="64"
                     loading="eager" decoding="async">

                <span class="bot-text">
                    <strong>Узнайте, что говорят пророки о вашей ситуации</strong><br>
                    Откройте бота «Спроси Пророка» в Telegram — поиск по Библии без AI-генерации.
                </span>
            </a>
        </div>
"@

$landingBotBox = @"
        <div class="landing-bot-box">
            <a href="https://t.me/SprosiProroka_bot"
               class="landing-bot-link js-telegram-cta"
               data-cta="article-inline"
               data-section="bottom"
               aria-label="Открыть бота Спроси Пророка в Telegram">
                <img src="/prorok/assets/images/book.png"
                     alt="Библейский бот"
                     class="landing-bot-avatar"
                     width="64" height="64"
                     loading="eager" decoding="async">
            </a>
            <p class="landing-bot-text">
                <strong>Бот в Telegram</strong>
                Поиск по Священным Текстам
            </p>
        </div>
"@

# =============================================
# CSV Parser
# =============================================
function Read-SeoCsv {
    param([string]$path)
    if (-not (Test-Path $path)) { return @() }

    $lines = Get-Content $path -Encoding UTF8
    $entries = @()

    foreach ($line in $lines) {
        if ($line -match '^\s*$') { continue }
        if ($line -match '^@"' -or $line -match '"@$') { continue }
        if ($line -match '^file,') { continue }

        $parts = $line -split ','
        if ($parts.Count -ge 3) {
            $slug = $parts[0].Trim().Trim('"')
            $title = $parts[1].Trim().Trim('"')
            $desc = ($parts[2..($parts.Count-1)] -join ',').Trim().Trim('"')

            if ($slug -match '^[a-zA-Z0-9_\-]+\.html$') {
                $entries += @{
                    slug = $slug
                    title = $title
                    description = $desc
                    canonical = "$baseUrl/$slug"
                }
            }
        }
    }
    return $entries
}

# =============================================
# Stub Markdown Generator
# =============================================
function New-StubMarkdown {
    param([string]$title, [string]$description, [string]$canonical)

    $md = "---`n"
    $md += "title: `"$title`"`n"
    $md += "description: `"$description`"`n"
    $md += "canonical: `"$canonical`"`n"
    $md += "---`n`n"
    $md += "# $title`n`n"

    # --- Introduction (~150 words) ---
    $md += "## Введение`n`n"
    $md += "Тема `"$title`" занимает важное место в духовной жизни каждого человека. $description. В современном мире этот вопрос становится особенно актуальным, поскольку миллионы людей ищут ответы и guidance в своей повседневной жизни.`n`n"
    $md += "На протяжении веков верующие обращались к Священному Писанию, чтобы найти мудрость и утешение. Библия не обходит стороной ни одну из важных тем человеческого существования, предлагая не абстрактные теории, а живую, действенную истину. Каждое поколение заново открывает для себя глубину библейской мудрости и находит в ней опору для своей веры и практические ориентиры для жизни.`n`n"
    $md += "В этой статье мы подробно рассмотрим библейский взгляд на данный вопрос, обратимся к ключевым текстам Священного Писания, изучим исторический контекст и предложим практические шаги, которые помогут применить эти знания в повседневной жизни. Наша цель — не просто информировать, но вдохновить на deeper размышление и реальные изменения.`n`n"

    # --- Biblical foundations (~300 words) ---
    $md += "## Библейские основания`n`n"
    $md += "Священное Писание содержит множество прямых и косвенных указаний на эту тему. Ветхий Завет закладывает фундамент понимания, а Новый Завет раскрывает его полноту через учение Иисуса Христа и апостолов. От первых страниц Книги Бытия до заключительных глав Откровения мы видим единую линию Божьего замысла для человечества.`n`n"
    $md += "В Книге Псалмов мы находим множество мест, которые непосредственно связаны с этим вопросом. Псалмопевец Давид, прошедший через множество испытаний, оставил нам бесценные примеры того, как обращаться к Богу в различных обстоятельствах жизни. Его слова, записанные тысячи лет назад, продолжают звучать с удивительной силой и актуальностью.`n`n"
    $md += "Пророки Ветхого Завета — Исаия, Иеремия, Иезекииль — также обращались к этой теме в своих посланиях к народу Израиля. Их пророчества содержали не только предупреждения, но и обетования надежды и восстановления. Эти тексты показывают, что Бог всегда был заинтересован в благополучии Своего народа и предлагал конкретные пути решения.`n`n"
    $md += "В Новом Завете апостол Павел в своих посланиях развивает эту тему ещё глубже. Его богословские размышления в Послании к Римлянам, Коринфянам и Ефесянам дают нам системное понимание того, как Бог действует в жизни верующих. Павел не просто теоретизирует — он делится собственным опытом, пройдя через множество трудностей и испытаний.`n`n"
    $md += "Нагорная проповедь Иисуса Христа содержит ключевые принципы, которые непосредственно применимы к этой теме. Блаженства, заповеди о любви, прощении и доверии Богу образуют прочную основу для практического применения веры в повседневной жизни.`n`n"

    # --- Historical context (~200 words) ---
    $md += "## Исторический контекст`n`n"
    $md += "Для глубокого понимания этой темы важно обратиться к историческому контексту, в котором были написаны библейские тексты. Древний мир существенно отличался от нашего: другие социальные структуры, культурные нормы и политические реалии формировали особый контекст для духовных истин.`n`n"
    $md += "В первом веке нашей эры ранняя церковь столкнулась с множеством вызовов, которые требовали осмысления через призму веры. Апостолы и первые христиане находили ответы в учении Христа и применяли их к конкретным обстоятельствам своей жизни. Их опыт остаётся ценным примером для нас сегодня.`n`n"
    $md += "На протяжении истории церкви богословы и пасторы продолжали размышлять над этими вопросами. Отцы церкви, средневековые схоласты, реформаторы и современные богословы — все они вносили свой вклад в понимание данной темы. Это богатое наследие мысли и опыта помогает нам видеть картину в более широкой перспективе.`n`n"
    $md += "Реформация XVI века принесла новое осмысление многих библейских истин. Мартин Лютер, Жан Кальвин и другие реформаторы подчеркнули важность личного отношения с Богом и прямого обращения к Писанию. Их наследие продолжает влиять на наше понимание веры и практики.`n`n"

    # --- Practical steps (~300 words) ---
    $md += "## Практические шаги для применения`n`n"
    $md += "Знание без практики остаётся мёртвым грузом. Поэтому крайне важно не только понимать библейские принципы, но и активно применять их в повседневной жизни. Вот конкретные шаги, которые помогут вам начать:`n`n"
    $md += "### 1. Ежедневная молитва и размышление`n`n"
    $md += "Начните каждый день с молитвы и чтения Писания. Посвятите хотя бы 15-20 минут тому, чтобы побыть в тишине перед Богом, прочитать главу из Библии и поразмышлять над её значением для вашей жизни. Регулярность в этом деле важнее продолжительности — лучше меньше, но каждый день, чем много, но от случая к случаю.`n`n"
    $md += "### 2. Изучение Слова Божьего`n`n"
    $md += "Углубляйте своё знание Писания через систематическое изучение. Читайте не только отдельные стихи, но целые книги Библии, понимая их контекст. Используйте толкования, комментарии и учебные пособия, которые помогают лучше понять текст. Помните, что Слово Божье — это живое послание, которое открывается нам по мере нашего духовного роста.`n`n"
    $md += "### 3. Общение с верующими`n`n"
    $md += "Не изолируйтесь от других верующих. Найдите общину, группу или наставника, с которыми можно обсуждать вопросы веры и получать поддержку. Совместное изучение Писания и взаимная молитва укрепляют веру и помогают видеть ситуации с разных сторон. Библия говорит, что где двое или трое собраны во имя Христа, там и Он посреди них.`n`n"
    $md += "### 4. Практика служения`n`n"
    $md += "Вера проявляется в делах. Ищите возможности служить другим людям — в семье, на работе, в церкви и в обществе. Служение не обязательно должно быть грандиозным: простой акт доброты, внимательное выслушивание или практическая помощь могут изменить чью-то жизнь и укрепить вашу собственную веру.`n`n"
    $md += "### 5. Доверие Богу в испытаниях`n`n"
    $md += "Трудности неизбежны, но именно в них наша вера проходит испытание и очищается. Вместо того чтобы впадать в отчаяние, обращайтесь к Богу в молитве, ищите Его лицо и доверяйтесь Его планам. Помните обетование из Римлянам 8:28 — всё содействует ко благу любящим Бога.`n`n"

    # --- Common misconceptions (~200 words) ---
    $md += "## Распространённые заблуждения`n`n"
    $md += "Вокруг этой темы существует множество заблуждений, которые мешают людям правильно понимать и применять библейскую истину. Важно разобраться в них, чтобы не быть введёнными в заблуждение.`n`n"
    $md += "**Заблуждение 1: Вера исключает сомнения.** На самом деле, сомнения — естественная часть духовного пути. Даже ученики Иисуса сомневались, и Он не осуждал их за это. Важно не подавлять сомнения, а честно приносить их к Богу и искать ответы в Писании и общении с верующими.`n`n"
    $md += "**Заблуждение 2: Бог наказывает за каждую ошибку.** Это представление противоречит библейскому образу Бога как любящего Отца. Бог действительно исправляет нас, но Его мотивация — любовь, а не гнев. Он относится к нам с милостью и терпением, понимая нашу слабость.`n`n"
    $md += "**Заблуждение 3: Достаточно только знаний.** Знание Библии без её применения подобно карте без путешествия. Иаков предупреждает, что вера без дел мертва. Истинная вера всегда приводит к реальным изменениям в жизни и отношениях.`n`n"
    $md += "**Заблуждение 4: Духовный рост — это быстрый процесс.** На самом деле, духовное созревание — это путь длиною в жизнь. Не существует мгновенных решений для глубоких вопросов. Будьте терпеливы с собой и доверяйтесь Божьему времени.`n`n"

    # --- Faith in modern world (~200 words) ---
    $md += "## Вера в современном мире`n`n"
    $md += "Современный мир ставит перед верующими уникальные вызовы, которых не знали предыдущие поколения. Информационная перегрузка, стремительный ритм жизни, относивизм ценностей — всё это создаёт среду, в которой особенно трудно сохранять глубокую, осмысленную веру.`n`n"
    $md += "Однако именно в таких условиях библейские истины приобретают особую ценность. Они предлагают якорь стабильности в мире постоянных перемен. Принципы любви, прощения, честности и верности не устаревают — они остаются надёжными ориентирами в любую эпоху.`n`n"
    $md += "Технологии и социальные сети также создают новые возможности для распространения Евангелия и общения верующих. Онлайн-изучение Библии, подкасты о вере, мобильные приложения для молитвы — все эти инструменты могут стать помощниками в духовной жизни, если использовать их мудро.`n`n"
    $md += "Важно помнить, что вера — это не бегство от реальности, а способ жить в ней более полно и осмысленно. Христианская вера не призывает к изоляции от мира, а предлагает быть солью и светом в нём, влияя на окружающее пространство любовью и истиной.`n`n"

    # --- Conclusion (~150 words) ---
    $md += "## Заключение`n`n"
    $md += "Тема `"$title`" — это лишь одна из граней великой истины, которую Бог открывает нам через Своё Слово. Каждый, кто искренне ищет ответы, найдёт их в Писании, в молитве и в общении с другими верующими.`n`n"
    $md += "Помните, что духовный путь — это не спринт, а марафон. Не бойтесь задавать вопросы, искать, сомневаться и расти. Бог, Который создал вас, знает ваше сердце и готов вести вас на каждом шаге этого пути.`n`n"
    $md += "Начните сегодня: откройте Библию, обратитесь к Богу в молитве и поделитесь своими мыслями с близким человеком. Маленький шаг сегодня может привести к большим переменам завтра. Как говорит Писание: «Ищите — и найдёте, стучите — и отворят вам» (Матфея 7:7).`n`n"

    # --- FAQ ---
    $md += "## FAQ`n`n"
    $md += "### Что говорит Библия на эту тему?`n`n"
    $md += "Библия содержит множество мест, которые говорят об этом. Ключевые стихи можно найти в Псалмах, Притчах и посланиях апостолов. Например, Псалом 22 напоминает нам, что Господь — Пастырь наш и мы ни в чём не будем нуждаться. В Послании к Филиппийцам 4:13 апостол Павел говорит, что всё может в укрепляющем его Иисусе Христе. Эти и многие другие тексты показывают, что Бог не остаётся в стороне от наших вопросов и трудностей, а предлагает реальную помощь и руководство через Своё Слово и Святого Духа.`n`n"
    $md += "### Как применить это в повседневной жизни?`n`n"
    $md += "Начните с ежедневной молитвы и чтения Писания — хотя бы 15 минут в день. Обсуждайте эти вопросы с наставником или в группе верующих. Применяйте библейские принципы в конкретных ситуациях: на работе, в семье, в отношениях с друзьями. Ведите дневник, записывая, как Бог отвечает на ваши молитвы и как Его Слово становится актуальным в вашей повседневной жизни. Помните, что маленькие последовательные шаги приводят к большим изменениям. Не пытайтесь изменить всё сразу — двигайтесь постепенно, доверяя Богу каждый новый день.`n`n"
    $md += "### Где найти дополнительную помощь и поддержку?`n`n"
    $md += "Обратитесь к пастору или христианскому консультанту в вашей общине. Вы также можете задать вопрос нашему боту «Спроси Пророка» в Telegram для поиска по Священным Текстам. Кроме того, существует множество христианских книг, подкастов и онлайн-ресурсов, которые могут помочь вам в духовном росте. Важно не оставаться наедине со своими вопросами — общение с другими верующими и опытными наставниками может кардинально изменить ваше понимание и обогатить вашу духовную жизнь.`n`n"

    return $md
}

# =============================================
# Markdown → HTML Converter
# =============================================
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
            $htmlLines += "    <h2>$($Matches[1])</h2>"
            continue
        }
        if ($trimmed -match '^# (.+)') {
            if ($skipFirstH1) { $skipFirstH1 = $false; continue }
            $htmlLines += "    <h2>$($Matches[1])</h2>"
            continue
        }

        if ($trimmed -match '^\d+\.\s+(.+)') {
            $itemText = $Matches[1]
            $itemText = $itemText -replace '\*\*(.+?)\*\*', '<strong>$1</strong>'
            $itemText = $itemText -replace '\*(.+?)\*', '<em>$1</em>'
            $htmlLines += "    <p>$itemText</p>"
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

# =============================================
# FAQ Schema Generator (JSON-LD)
# =============================================
function New-FaqSchema {
    param([string]$mdBody)

    $faqItems = @()
    $lines = $mdBody -split "`n"
    $currentQ = $null
    $currentA = @()
    $inFaqSection = $false

    foreach ($line in $lines) {
        $trimmed = $line.Trim()

        if ($trimmed -match '^##\s+FAQ\s*$') {
            $inFaqSection = $true
            continue
        }

        if ($inFaqSection -and $trimmed -match '^##\s+(?!FAQ)') {
            $inFaqSection = $false
        }

        if (-not $inFaqSection) { continue }

        if ($trimmed -match '^###\s+(.+)') {
            if ($currentQ) {
                $faqItems += @{ q = $currentQ; a = ($currentA -join ' ').Trim() }
            }
            $currentQ = $Matches[1].Trim()
            $currentA = @()
        } elseif ($currentQ -and $trimmed -ne '') {
            $clean = $trimmed -replace '^\*\*(.+?)\*\*$', '$1' -replace '\*(.+?)\*', '$1'
            $currentA += $clean
        }
    }
    if ($currentQ) {
        $faqItems += @{ q = $currentQ; a = ($currentA -join ' ').Trim() }
    }

    if ($faqItems.Count -eq 0) { return '' }

    $entities = @()
    foreach ($item in $faqItems) {
        $safeQ = [System.Security.SecurityElement]::Escape($item.q)
        $safeA = [System.Security.SecurityElement]::Escape($item.a)
        $entities += "        {`n          `"@type`": `"Question`",`n          `"name`": `"$safeQ`",`n          `"acceptedAnswer`": {`n            `"@type`": `"Answer`",`n            `"text`": `"$safeA`"`n          }`n        }"
    }

    $json = "<script type=`"application/ld+json`">`n"
    $json += "{`n"
    $json += "  `"@context`": `"https://schema.org`",`n"
    $json += "  `"@type`": `"FAQPage`",`n"
    $json += "  `"mainEntity`": [`n"
    $json += ($entities -join ",`n") + "`n"
    $json += "  ]`n"
    $json += "}`n"
    $json += "</script>"
    return $json
}

# =============================================
# Breadcrumb Schema Generator (JSON-LD)
# =============================================
function New-BreadcrumbSchema {
    param([string]$slug, [string]$title)

    $items = @()
    $items += "        { `"@type`": `"ListItem`", `"position`": 1, `"name`": `"Главная`", `"item`": `"$baseUrl/index.html`" }"
    $items += "        { `"@type`": `"ListItem`", `"position`": 2, `"name`": `"$([System.Security.SecurityElement]::Escape($title))`", `"item`": `"$baseUrl/$slug`" }"

    $json = "<script type=`"application/ld+json`">`n"
    $json += "{`n"
    $json += "  `"@context`": `"https://schema.org`",`n"
    $json += "  `"@type`": `"BreadcrumbList`",`n"
    $json += "  `"itemListElement`": [`n"
    $json += ($items -join ",`n") + "`n"
    $json += "  ]`n"
    $json += "}`n"
    $json += "</script>"
    return $json
}

# =============================================
# Breadcrumb HTML Generator
# =============================================
function New-BreadcrumbHtml {
    param([string]$slug, [string]$title)
    $safeTitle = [System.Security.SecurityElement]::Escape($title)
    return "<ol style=`"list-style:none;display:flex;gap:8px;padding:0;font-size:0.85rem;`">`n" +
           "  <li><a href=`"/prorok/index.html`" style=`"color:#aaa;`">Главная</a></li>`n" +
           "  <li style=`"color:#666;`">›</li>`n" +
           "  <li style=`"color:#ccc;`">$safeTitle</li>`n" +
           "</ol>"
}

# =============================================
# Article Schema Generator (JSON-LD)
# =============================================
function New-ArticleSchema {
    param([string]$slug, [string]$title, [string]$description, [string]$canonical)

    $safeTitle = [System.Security.SecurityElement]::Escape($title)
    $safeDesc = [System.Security.SecurityElement]::Escape($description)
    $datePublished = $today

    $json = "<script type=`"application/ld+json`">`n"
    $json += "{`n"
    $json += "  `"@context`": `"https://schema.org`",`n"
    $json += "  `"@type`": `"Article`",`n"
    $json += "  `"headline`": `"$safeTitle`",`n"
    $json += "  `"description`": `"$safeDesc`",`n"
    $json += "  `"datePublished`": `"$datePublished`",`n"
    $json += "  `"author`": { `"@type`": `"Organization`", `"name`": `"Пророк`" },`n"
    $json += "  `"publisher`": { `"@type`": `"Organization`", `"name`": `"Пророк`" },`n"
    $json += "  `"mainEntityOfPage`": `"$canonical`"`n"
    $json += "}`n"
    $json += "</script>"
    return $json
}

# =============================================
# Related Articles Generator
# =============================================
function New-RelatedLinks {
    param(
        [string]$currentSlug,
        [hashtable]$allMeta
    )

    $otherKeys = @($allMeta.Keys) | Where-Object { $_ -ne $currentSlug } | Sort-Object { Get-Random } | Select-Object -First 4

    if ($otherKeys.Count -eq 0) { return '' }

    $links = @()
    foreach ($key in $otherKeys) {
        $m = $allMeta[$key]
        $safeTitle = [System.Security.SecurityElement]::Escape($m.title)
        $links += "      <li><a href=`"/prorok/$key`">$safeTitle</a></li>"
    }

    $html = "<aside class=`"related-articles`">`n"
    $html += "  <h3>Читайте также</h3>`n"
    $html += "  <ul>`n"
    $html += ($links -join "`n") + "`n"
    $html += "  </ul>`n"
    $html += "</aside>"
    return $html
}

# =============================================
# Article Page Generator
# =============================================
function New-ArticlePage {
    param(
        [string]$slug,
        [string]$title,
        [string]$description,
        [string]$contentHtml,
        [string]$canonical,
        [string]$faqSchema,
        [string]$breadcrumbSchema,
        [string]$breadcrumbHtml,
        [string]$relatedLinks,
        [string]$articleSchema
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
                       -replace '\{\{YEAR\}\}', $year `
                       -replace '\{\{CONTENT\}\}', $contentHtml `
                       -replace '\{\{FAQ_SCHEMA\}\}', $faqSchema `
                       -replace '\{\{BREADCRUMB_SCHEMA\}\}', $breadcrumbSchema `
                       -replace '\{\{BREADCRUMB_HTML\}\}', $breadcrumbHtml `
                       -replace '\{\{RELATED_LINKS\}\}', $relatedLinks `
                       -replace '\{\{ARTICLE_SCHEMA\}\}', $articleSchema

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

# =============================================
# Sitemap Generator
# =============================================
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
        $xml += "    <lastmod>$today</lastmod>`n"
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

# =============================================
# Search Index Generator
# =============================================
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

# ============================================================
# === MAIN ===
# ============================================================

Write-Host "=== Prorok Site Generator ==="
Write-Host ""

# 1. Parse CSV
$csvEntries = Read-SeoCsv -path $csvPath
Write-Host "SEO pages from CSV: $($csvEntries.Count)"

# 2. Generate/regenerate stub .md files for every CSV entry
$stubsCreated = 0
foreach ($entry in $csvEntries) {
    $mdPath = Join-Path $articlesDir $entry.slug.Replace('.html', '.md')
    $shouldCreate = $true
    if (Test-Path $mdPath) {
        # Only overwrite if file is a stub (< 50 lines)
        $lineCount = (Get-Content $mdPath).Count
        if ($lineCount -gt 50) { $shouldCreate = $false }
    }
    if ($shouldCreate) {
        $stubMd = New-StubMarkdown -title $entry.title -description $entry.description -canonical $entry.canonical
        [System.IO.File]::WriteAllText($mdPath, $stubMd, [System.Text.UTF8Encoding]::new($false))
        $stubsCreated++
    }
}
if ($stubsCreated -gt 0) {
    Write-Host "Stub .md files created/updated: $stubsCreated"
}

# 3. Also scan for any extra .md files not in CSV
$mdFiles = Get-ChildItem -Path $articlesDir -Filter *.md -Recurse | Sort-Object FullName
Write-Host "Total .md files: $($mdFiles.Count)"
Write-Host ""

$allUrls = @()
$allSlugs = @()
$allMeta = @{}
$pagesGenerated = 0

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
        $canonical = "$baseUrl/$slug"
    }

    $contentHtml = Convert-MarkdownToHtml -md $mdBody
    $plainContent = ($contentHtml -replace '<[^>]+>', ' ' -replace '\s+', ' ').Trim()

    $allUrls += $canonical
    $allSlugs += $slug
    $allMeta[$slug] = @{ title = $title; desc = $description; content = $plainContent }
    $pagesGenerated++
}

# 4. Second pass: generate pages with full schema + related links
Write-Host "Generating article pages..."
foreach ($slug in $allSlugs) {
    $m = $allMeta[$slug]
    $mdFile = Get-ChildItem -Path $articlesDir -Filter ($slug -replace '\.html$', '.md') -Recurse | Select-Object -First 1

    $mdBody = ""
    if ($mdFile) {
        $rawContent = Get-Content $mdFile.FullName -Raw -Encoding UTF8
        if ($rawContent -match '(?s)^---\s*\r?\n.+?\r?\n---\s*\r?\n(.*)$') {
            $mdBody = $Matches[1]
        }
    }

    $canonical = "$baseUrl/$slug"
    # Prefer canonical from frontmatter
    foreach ($entry in $csvEntries) {
        if ($entry.slug -eq $slug) {
            $canonical = $entry.canonical
            break
        }
    }

    $contentHtml = Convert-MarkdownToHtml -md $mdBody
    $faqSchema = New-FaqSchema -mdBody $mdBody
    $breadcrumbSchema = New-BreadcrumbSchema -slug $slug -title $m.title
    $breadcrumbHtml = New-BreadcrumbHtml -slug $slug -title $m.title
    $relatedLinks = New-RelatedLinks -currentSlug $slug -allMeta $allMeta
    $articleSchema = New-ArticleSchema -slug $slug -title $m.title -description $m.desc -canonical $canonical

    New-ArticlePage -slug $slug `
                    -title $m.title `
                    -description $m.desc `
                    -contentHtml $contentHtml `
                    -canonical $canonical `
                    -faqSchema $faqSchema `
                    -breadcrumbSchema $breadcrumbSchema `
                    -breadcrumbHtml $breadcrumbHtml `
                    -relatedLinks $relatedLinks `
                    -articleSchema $articleSchema
}

# 5. Religion section pages
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
                   -replace '\{\{YEAR\}\}', $year
    $outDir = Join-Path $outputDir (Split-Path $rp.slug -Parent)
    New-Item -Path $outDir -ItemType Directory -Force | Out-Null
    [System.IO.File]::WriteAllText((Join-Path $outputDir $rp.slug), $pageHtml, [System.Text.UTF8Encoding]::new($false))
    $allUrls += $rp.canonical
    $allSlugs += $rp.slug
    Write-Host "  Generated: $($rp.slug)"
    $pagesGenerated++
}

# 6. Homepage
$indexSlug = "index.html"
$indexCanonical = "$baseUrl/index.html"

$indexTemplatePath = Join-Path $templatesDir "landing.html"
$indexTemplate = Get-Content $indexTemplatePath -Raw -Encoding UTF8

$indexHtml = $indexTemplate -replace '\{\{GA_TAG\}\}', $gaTag `
                          -replace '\{\{BOT_BOX\}\}', $landingBotBox `
                          -replace '\{\{YEAR\}\}', $year

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

