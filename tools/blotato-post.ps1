# =============================================================================
# LUMARINNE — Blotato Social Media Posting Script
# Handles Instagram + Facebook carousels and single-image posts via Blotato API
# =============================================================================
#
# REQUIREMENTS:
#   - Run in Windows PowerShell (not PowerShell Core / PS7)
#   - Images must be PNG files in $imgFolder
#   - System.Drawing is used to build text-overlay carousel slides
#
# USAGE — EACH TIME:
#   1. Open Windows PowerShell
#   2. Paste this entire script and press Enter (or run: . .\blotato-post.ps1)
#   3. Define your post content (slides, captions) — see CONTENT SECTION below
#   4. Call: Post-IG $caption $urls $scheduleTime
#            Post-FB $caption $urls $scheduleTime
#      Use $null for $scheduleTime to post immediately (live)
#
# SCHEDULING FORMAT:  "2026-04-15T14:00:00Z"  (UTC — 14:00 UTC = 10am EDT)
#
# INSTAGRAM LIMITS:
#   - Maximum 5 hashtags per post (Blotato enforces this)
#   - Maximum 10 images per carousel
#
# =============================================================================

# ---- CONFIGURATION (do not change these) ------------------------------------

Add-Type -AssemblyName System.Drawing

$blotatoUrl = "https://mcp.blotato.com/mcp"
$apiKey     = "blt_1yk75Ud+MZHzG4H5kAVPFct/UABsw2DoIJg8r0OHNM4="

$hdrs = @{
    "Content-Type"    = "application/json"
    "blotato-api-key" = $apiKey
    "Accept"          = "application/json, text/event-stream"
}

$igId    = "39325"            # lumarinne_lifestyle (Instagram)
$fbId    = "25679"            # Susanne Lucas Shahidi (Facebook account)
$fbPage  = "972241189295177"  # LUMARINNE-Lifestyle (Facebook Page)

$imgFolder = "C:\Users\susan\OneDrive\Desktop\BlotatoStoryImages"
$tmpFolder = "$env:TEMP\LumaSlides"

if (-not (Test-Path $tmpFolder)) { New-Item -ItemType Directory -Path $tmpFolder | Out-Null }

# ---- CORE FUNCTIONS (load these every session) ------------------------------

# Call any Blotato MCP tool and parse JSON response.
# Returns parsed object, or $null on error.
# NOTE: Instagram returns plain text, not JSON — use Invoke-RestMethod directly for IG posts.
function Invoke-Blotato($toolName, $toolArgs) {
    $body = @{
        jsonrpc = "2.0"; id = 1; method = "tools/call"
        params  = @{ name = $toolName; arguments = $toolArgs }
    } | ConvertTo-Json -Depth 10
    try {
        $r = Invoke-RestMethod -Uri $blotatoUrl -Method Post -Headers $hdrs -Body $body -ErrorAction Stop
        if ($r.error) { Write-Host "  BLOTATO ERROR: $($r.error.message)"; return $null }
        return $r.result.content[0].text | ConvertFrom-Json
    } catch {
        Write-Host "  EXCEPTION: $($_.Exception.Message)"; return $null
    }
}

# Upload a PNG file to Blotato storage. Returns the public URL, or $null on failure.
function Upload-Image($filePath) {
    $name = [System.IO.Path]::GetFileName($filePath)
    Write-Host "    Uploading: $name"
    $ps = Invoke-Blotato "blotato_create_presigned_upload_url" @{ filename=$name; contentType="image/png" }
    if (-not $ps) { Write-Host "    FAILED: $name"; return $null }
    $bytes = [System.IO.File]::ReadAllBytes($filePath)
    Invoke-RestMethod -Uri $ps.presignedUrl -Method Put -Body $bytes -ContentType "image/png" | Out-Null
    Write-Host "    OK -> $($ps.publicUrl)"
    return $ps.publicUrl
}

# Upload an array of file paths. Returns array of public URLs.
function Upload-All($paths) {
    $urls = @()
    foreach ($p in $paths) {
        $u = Upload-Image $p
        if ($u) { $urls += $u }
    }
    return $urls
}

# Build a text-overlay slide image using System.Drawing.
# Draws $text over $coverPath with a dark overlay, gold header, and footer.
# $slideLabel = e.g. "Part 1 of 6  |  My Awakening Story"
function Build-Slide($coverPath, $text, $outPath, $slideLabel) {
    $img = [System.Drawing.Image]::FromFile($coverPath)
    $bmp = New-Object System.Drawing.Bitmap($img.Width, $img.Height)
    $g   = [System.Drawing.Graphics]::FromImage($bmp)

    # Draw cover image
    $g.DrawImage($img, 0, 0, $img.Width, $img.Height)

    # Dark overlay for readability
    $g.FillRectangle(
        (New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(155, 0, 0, 0))),
        0, 0, $bmp.Width, $bmp.Height)

    $sf = New-Object System.Drawing.StringFormat
    $sf.Alignment     = [System.Drawing.StringAlignment]::Center
    $sf.LineAlignment = [System.Drawing.StringAlignment]::Center

    # Body text (white, Georgia italic, centered)
    $g.DrawString(
        $text,
        (New-Object System.Drawing.Font("Georgia", 30, [System.Drawing.FontStyle]::Regular)),
        (New-Object System.Drawing.SolidBrush([System.Drawing.Color]::White)),
        [System.Drawing.RectangleF]::new(80, 80, $bmp.Width - 160, $bmp.Height - 200),
        $sf)

    # Footer bar
    $g.FillRectangle(
        (New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(200, 0, 0, 0))),
        0, $bmp.Height - 80, $bmp.Width, 80)

    # Footer text (gold, Georgia italic)
    $sfF = New-Object System.Drawing.StringFormat
    $sfF.Alignment     = [System.Drawing.StringAlignment]::Center
    $sfF.LineAlignment = [System.Drawing.StringAlignment]::Center
    $g.DrawString(
        $slideLabel,
        (New-Object System.Drawing.Font("Georgia", 17, [System.Drawing.FontStyle]::Italic)),
        (New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 212, 175))),
        [System.Drawing.RectangleF]::new(0, $bmp.Height - 80, $bmp.Width, 80),
        $sfF)

    $bmp.Save($outPath, [System.Drawing.Imaging.ImageFormat]::Png)
    $g.Dispose(); $bmp.Dispose(); $img.Dispose()
    $sfF.Dispose(); $sf.Dispose()
}

# Build all slides for a post.
# $postNum   = number used in temp file names (any unique string, e.g. 1, "map")
# $coverPath = full path to the cover PNG
# $texts     = array where index 0 is empty ("") and 1..N are slide texts
# $label     = footer label, e.g. "Part 1 of 6  |  My Awakening Story"
# Returns array of file paths (cover first, then text slides).
function Build-Slides($postNum, $coverPath, $texts, $label) {
    $paths = @($coverPath)
    for ($i = 1; $i -lt $texts.Count; $i++) {
        $out = "$tmpFolder\p${postNum}_s${i}.png"
        Build-Slide $coverPath $texts[$i] $out $label
        $paths += $out
    }
    return $paths
}

# Post to Instagram (raw response — IG returns plain text, not JSON).
# $sched = ISO 8601 UTC string, or $null to post live immediately.
function Post-IG($caption, $mediaUrls, $sched) {
    $postArgs = @{ accountId=$igId; platform="instagram"; text=$caption; mediaUrls=$mediaUrls }
    if ($sched) { $postArgs.scheduledTime = $sched }
    $r = Invoke-RestMethod -Uri $blotatoUrl -Method Post -Headers $hdrs -Body (
        @{ jsonrpc="2.0"; id=1; method="tools/call"; params=@{ name="blotato_create_post"; arguments=$postArgs } } |
        ConvertTo-Json -Depth 10)
    Write-Host "  IG: $($r.result.content[0].text)"
}

# Post to Facebook (returns JSON — parsed and displayed).
# $sched = ISO 8601 UTC string, or $null to post live immediately.
function Post-FB($caption, $mediaUrls, $sched) {
    $postArgs = @{ accountId=$fbId; platform="facebook"; pageId=$fbPage; text=$caption; mediaUrls=$mediaUrls }
    if ($sched) { $postArgs.scheduledTime = $sched }
    $r = Invoke-Blotato "blotato_create_post" $postArgs
    Write-Host "  FB: $($r | ConvertTo-Json -Compress)"
}

Write-Host "Lumarinne Blotato functions loaded. Ready to post." -ForegroundColor Green
Write-Host "Image folder: $imgFolder"
Write-Host "Temp folder:  $tmpFolder"

# =============================================================================
# CONTENT SECTION — Edit this for each new posting campaign
# =============================================================================
#
# STEP 1: Define slide texts for each carousel post.
#         Index 0 must be "" (empty — slide 1 is always the plain cover image).
#         Each subsequent string becomes one text-overlay slide.
#
# Example:
#   $slides = @(
#       "",
#       "First slide text here.",
#       "Second slide text here.",
#       "Third slide text here."
#   )
#
# STEP 2: Define captions.
#         Instagram: 5 hashtags max.
#         Facebook: no hashtag limit, can be longer/more personal.
#
# STEP 3: Build, upload, and post.
#
# --- CAROUSEL POST EXAMPLE ---
#
#   $slides = @("", "Slide 2 text.", "Slide 3 text.")
#   $label  = "My Series  |  lumarinne.com"
#   $igCap  = "Caption here.`n`n#tag1 #tag2 #tag3 #tag4 #tag5"
#   $fbCap  = "Caption here, can be longer and have more hashtags."
#
#   $urls = Upload-All (Build-Slides "postname" "$imgFolder\cover.png" $slides $label)
#   Write-Host "$($urls.Count) slides uploaded"
#
#   Post-IG $igCap $urls "2026-05-01T14:00:00Z"   # 10am EDT
#   Post-FB $fbCap $urls "2026-05-01T14:00:00Z"
#
# --- SINGLE IMAGE POST EXAMPLE ---
#
#   $url = Upload-Image "$imgFolder\cover.png"
#   Post-IG $igCap @($url) $null    # $null = post live now
#   Post-FB $fbCap @($url) $null
#
# --- LIVE POST NOW (no schedule) ---
#   Use $null as the third argument to Post-IG / Post-FB
#
# =============================================================================
