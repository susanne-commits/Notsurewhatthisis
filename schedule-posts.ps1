# Lumarinne Lifestyle — Blotato Post Scheduler (Windows PowerShell)
# Schedules the 8-post Awakening Story series to Instagram and Facebook.
#
# HOW TO RUN:
#   1. Open PowerShell (press the Windows key, type PowerShell, press Enter)
#   2. Paste this one line and press Enter:
#      irm https://raw.githubusercontent.com/susanne-commits/Notsurewhatthisis/claude/schedule-blotato-posts-TOl1x/schedule-posts.ps1 | iex

$ApiKey  = "blt_1yk75Ud+MZHzG4H5kAVPFct/UABsw2DoIJg8r0OHNM4="
$BaseUrl = "https://backend.blotato.com/v2"
$Headers = @{ "blotato-api-key" = $ApiKey; "Content-Type" = "application/json" }

# ── Step 1: Discover connected accounts ──────────────────────────────────────

Write-Host "Fetching connected social accounts..."
try {
    $Accounts = Invoke-RestMethod -Uri "$BaseUrl/users/me/accounts" -Headers $Headers -Method GET
} catch {
    Write-Host "Error: Could not reach Blotato. Check your internet connection."
    Write-Host $_.Exception.Message
    exit 1
}

$IgAccountId = ($Accounts.items | Where-Object { $_.platform -eq "instagram" } | Select-Object -First 1).id
$FbAccountId = ($Accounts.items | Where-Object { $_.platform -eq "facebook" } | Select-Object -First 1).id

Write-Host ""
Write-Host "Instagram account ID : $(if ($IgAccountId) { $IgAccountId } else { 'not found' })"
Write-Host "Facebook account ID  : $(if ($FbAccountId) { $FbAccountId } else { 'not found' })"
Write-Host ""

if (-not $IgAccountId -and -not $FbAccountId) {
    Write-Host "Error: No Instagram or Facebook accounts found."
    Write-Host "Connect them at https://my.blotato.com/settings/social-accounts"
    exit 1
}

# Get Facebook page ID from subaccounts
$FbPageId = ""
if ($FbAccountId) {
    try {
        $Subaccounts = Invoke-RestMethod -Uri "$BaseUrl/users/me/accounts/$FbAccountId/subaccounts" -Headers $Headers -Method GET
        $FbPageId = $Subaccounts.items[0].pageId
        Write-Host "Facebook page ID     : $(if ($FbPageId) { $FbPageId } else { 'not found in subaccounts' })"
    } catch {
        Write-Host "Facebook page ID     : ERROR fetching subaccounts — $($_.Exception.Message)"
    }
} else {
    Write-Host "Facebook page ID     : skipped (no Facebook account)"
}
Write-Host ""

# ── Step 2: Scheduling function ───────────────────────────────────────────────

function Schedule-Post {
    param(
        [string]$Platform,
        [string]$AccountId,
        [string]$Text,
        [string]$ScheduledTime,
        [string]$Label,
        [string]$PageId = "",
        [string[]]$MediaUrls = @()
    )

    if ($Platform -eq "facebook" -and $PageId) {
        $Target = [ordered]@{ targetType = "facebook"; pageId = $PageId }
    } else {
        $Target = [ordered]@{ targetType = $Platform }
    }

    $Body = [ordered]@{
        post = [ordered]@{
            accountId = $AccountId
            content   = [ordered]@{
                text      = $Text
                mediaUrls = $MediaUrls
                platform  = $Platform
            }
            target = $Target
        }
        scheduledTime = $ScheduledTime
    } | ConvertTo-Json -Depth 10

    try {
        Invoke-RestMethod -Uri "$BaseUrl/posts" -Headers $Headers -Method POST -Body $Body | Out-Null
        Write-Host "  + Scheduled: $Label ($Platform)"
    } catch {
        $ErrDetail = $_.ErrorDetails.Message
        Write-Host "  x Failed:    $Label ($Platform)"
        Write-Host "    HTTP $($_.Exception.Response.StatusCode.Value__): $ErrDetail"
    }
}

# ── Cover image URLs ──────────────────────────────────────────────────────────

$ImgBase    = "https://raw.githubusercontent.com/susanne-commits/Notsurewhatthisis/df2e17cb689fea2105afa2b705b9cfaa765a587b/blotato-posts"
$Img1       = @("$ImgBase/cover_1.png")
$Img2       = @("$ImgBase/cover_2.png")
$ImgCouncil = @("$ImgBase/cover_council.png")
$Img3       = @("$ImgBase/cover_3.png")
$Img4       = @("$ImgBase/cover_4.png")
$Img5       = @("$ImgBase/cover_5.png")
$Img6       = @("$ImgBase/cover_6.png")
$ImgMap     = @()   # cover_map.png not uploaded — add manually in Blotato

# ── Posts ─────────────────────────────────────────────────────────────────────

Write-Host "Scheduling posts..."
Write-Host ""

# POST 1: Part 1 — The Shattering  (April 8, 6pm EDT)
$Caption1 = @"
I've never told this story publicly before.

For a long time, I didn't think I was allowed to. It felt too raw. Too real. Too much.

But this is the story of how Lumarinne was born — and it didn't start with a business plan or a product idea. It started with a morning that broke everything.

This is Part 1 of my awakening story. I'll be sharing the full journey over the next two weeks — from the shattering, to the full moon circle on a Spanish beach, to the healers who saw something in me I couldn't see yet, to the woman I became on the other side.

If something in your life is shifting right now, you might see yourself in this story. That's not an accident.

Part 2 drops in 2 days. 🪶

#spiritualawakening #awakeningjourney #lumarinne #awakeningstory #startingover #healingjourney #womenwhoheal #lightworker #newchapter #findingmyself
"@

if ($IgAccountId) { Schedule-Post "instagram" $IgAccountId $Caption1 "2026-04-08T22:00:00+00:00" "Part 1 — The Shattering" "" $Img1 }
if ($FbAccountId) { Schedule-Post "facebook"  $FbAccountId $Caption1 "2026-04-08T22:00:00+00:00" "Part 1 — The Shattering" $FbPageId $Img1 }

# POST 2: Part 2 — The Full Moon  (April 10, 9am EDT)
$Caption2 = @"
The full moon is where it started.

Not the pain — that started before. But the opening. The moment the universe stopped whispering and started speaking directly.

A card was pulled that had never been pulled before. And then it was pulled again.

This is Part 2. If you're new here, start with Part 1 (link in bio).

Part 3 drops in 4 days — and it's the one that gave me chills to write. 🌙

#fullmooncircle #spiritualawakening #counciloflight #lumarinne #awakeningstory #energyhealing #oracledeck #moonritual #healingjourney #divinesigns
"@

if ($IgAccountId) { Schedule-Post "instagram" $IgAccountId $Caption2 "2026-04-10T13:00:00+00:00" "Part 2 — The Full Moon" "" $Img2 }
if ($FbAccountId) { Schedule-Post "facebook"  $FbAccountId $Caption2 "2026-04-10T13:00:00+00:00" "Part 2 — The Full Moon" $FbPageId $Img2 }

# POST 3: Council of Light — Companion Post  (April 12, 9am EDT)
$Caption3 = @"
In Part 2 of my story, I told you about the card.

The Council of Light — pulled twice in a row, something that had never happened in my healer's entire practice.

So what does this card actually mean?

The Council of Light represents divine orchestration. It's a message that you have a personal team of helpers in the spiritual realm — ascended masters, light beings, angels, and guides — who are devoted to helping you fulfill your soul's mission.

But here's the part that stopped me: because we live in a world where free will reigns, they cannot help you without your permission. You have to ask.

They can help with anything — nothing is too big or too small. Think of them as your personal team in the spirit realm, ready to step in the moment you invite them.

If you're a lightworker — someone who feels called to uplift others and raise consciousness — the Council of Light is where your personal mission originates.

The activation is simple: place your hands over your heart and say, "Council of Light, I am ready to receive your help for fulfilling my personal mission. Thank you for guiding me with clarity every step of the way and for sending me helpers and experiences that delight my mind, body, and soul."

This card was pulled for me twice. I don't believe that was random. I believe it was an invitation — and I accepted it.

If you're reading this and something in you just lit up, that's not an accident either. 🪶

#counciloflight #lightworker #spiritualguidance #oraclecards #divineorchestration #lumarinne #awakeningstory #spiritguides #angels #ascendedmasters
"@

if ($IgAccountId) { Schedule-Post "instagram" $IgAccountId $Caption3 "2026-04-12T13:00:00+00:00" "Council of Light" "" $ImgCouncil }
if ($FbAccountId) { Schedule-Post "facebook"  $FbAccountId $Caption3 "2026-04-12T13:00:00+00:00" "Council of Light" $FbPageId $ImgCouncil }

# POST 4: Part 3 — The Shopkeeper  (April 14, 9am EDT)
$Caption4 = @"
This is the part of the story that still gives me chills.

A woman in a tiny crystal shop in a Spanish village. She didn't speak my language. Her daughter translated over speakerphone. She insisted on reading my cards for free because she said she felt something the moment I walked in.

I don't know her name. I never learned it. But she saw something in me that I was only just beginning to see in myself.

Part 3 of my awakening story. Start from Part 1 if you're new (link in bio). 🪶

#synchronicity #crystalshop #tarotreading #spiritualawakening #lumarinne #awakeningstory #divinesigns #spain #healingjourney #trusttheuniverse
"@

if ($IgAccountId) { Schedule-Post "instagram" $IgAccountId $Caption4 "2026-04-14T13:00:00+00:00" "Part 3 — The Shopkeeper" "" $Img3 }
if ($FbAccountId) { Schedule-Post "facebook"  $FbAccountId $Caption4 "2026-04-14T13:00:00+00:00" "Part 3 — The Shopkeeper" $FbPageId $Img3 }

# POST 5: Part 4 — The Ankh  (April 16, 9am EDT)
$Caption5 = @"
"You are very protected."

Those four words changed how I understood everything that had happened to me.

The voice that told me to go talk to my son. The full moon that pulled me to the beach. The card that had never been pulled. The shopkeeper who saw me before I saw myself.

I wasn't just stumbling through an awakening. I was being guided through one.

Part 4. The ankh. The energy. And the woman who confirmed it all on my last night in Spain. 🪶

#reiki #ankh #energyhealing #rootchakra #spiritualprotection #lumarinne #awakeningstory #youareprotected #healingjourney #divineenergy
"@

if ($IgAccountId) { Schedule-Post "instagram" $IgAccountId $Caption5 "2026-04-16T13:00:00+00:00" "Part 4 — The Ankh" "" $Img4 }
if ($FbAccountId) { Schedule-Post "facebook"  $FbAccountId $Caption5 "2026-04-16T13:00:00+00:00" "Part 4 — The Ankh" $FbPageId $Img4 }

# POST 6: Part 5 — The Becoming  (April 18, 9am EDT)
$Caption6 = @"
This was the quiet part of the awakening. No healers. No cards. No sessions.

Just me, a journal, and five months of learning who I am without all the roles attached.

I am pretty much alone now. But I am not lonely. There is a difference the size of a universe between those two things.

Part 5. The becoming. 🪶

#becomingher #solitude #spiritualawakening #lumarinne #awakeningstory #lettinggo #newchapter #startingover #womenover40 #selfreclamation
"@

if ($IgAccountId) { Schedule-Post "instagram" $IgAccountId $Caption6 "2026-04-18T13:00:00+00:00" "Part 5 — The Becoming" "" $Img5 }
if ($FbAccountId) { Schedule-Post "facebook"  $FbAccountId $Caption6 "2026-04-18T13:00:00+00:00" "Part 5 — The Becoming" $FbPageId $Img5 }

# POST 7: Part 6 — Light by the Sea  (April 20, 9am EDT)
$Caption7 = @"
Luma: light. Marinne: the sea.

Born under the full moon, by the Mediterranean, in the middle of starting over.

This is Part 6. The final chapter — for now.

Thank you for reading this story. Thank you for being here. If any part of it made you feel seen, that's exactly why I wrote it.

I made a guide for women who are going through what I went through. It's called The Awakening Map. Link in bio. 🪶

#lumarinne #lightbythesea #awakeningstory #spiritualawakening #brandstory #womenwhoheal #startingover #italy #newbeginnings #awakeish
"@

if ($IgAccountId) { Schedule-Post "instagram" $IgAccountId $Caption7 "2026-04-20T13:00:00+00:00" "Part 6 — Light by the Sea" "" $Img6 }
if ($FbAccountId) { Schedule-Post "facebook"  $FbAccountId $Caption7 "2026-04-20T13:00:00+00:00" "Part 6 — Light by the Sea" $FbPageId $Img6 }

# POST 8: The Awakening Map — Product Launch  (April 22, 9am EDT)
$Caption8 = @"
When everything was happening to me in Spain — the full moon circles, the energy work, the cards, the signs — I kept searching for something that would tell me I wasn't crazy.

I googled "spiritual awakening" at 2am. I asked healers. I asked AI. I was looking for a guide that would say: this is real, this is what's happening, here's what comes next.

I never found it. So I built it.

The Awakening Map is a guided journal for women who are waking up and want to know they're not losing their minds.

Six stages. Education, journal prompts, and practical tools for each one. Written by a woman who went through it and documented it in real time — not by a guru looking backward.

This is designed to be printed and written in by hand. There is something about the connection between your brain, your eyes, and your hands — the physical act of writing — that helps your body process and release what your mind is holding. That's not an afterthought. It's by design.

`$22.22 — because in the language of angel numbers, 2222 represents alignment, trust, and divine timing. The very things this journal was built to help you find.

Link in bio. 🪶

#theawakeningmap #lumarinne #awakenishjournal #spiritualawakening #guidedjournal #womenwhoheal #awakeish #healingtools #journaling #awakeningstages
"@

# NOTE: cover_map.png was not uploaded — add the image manually in Blotato after scheduling.
if ($IgAccountId) { Schedule-Post "instagram" $IgAccountId $Caption8 "2026-04-22T13:00:00+00:00" "Awakening Map — Product Launch" "" $ImgMap }
if ($FbAccountId) { Schedule-Post "facebook"  $FbAccountId $Caption8 "2026-04-22T13:00:00+00:00" "Awakening Map — Product Launch" $FbPageId $ImgMap }

# ── Done ──────────────────────────────────────────────────────────────────────

Write-Host ""
Write-Host "Done. View your scheduled posts at https://my.blotato.com"
Write-Host ""
Write-Host "Schedule:"
Write-Host "  Apr 8  (Wed) 6pm EDT  — Part 1: The Shattering"
Write-Host "  Apr 10 (Fri) 9am EDT  — Part 2: The Full Moon"
Write-Host "  Apr 12 (Sun) 9am EDT  — Council of Light (companion)"
Write-Host "  Apr 14 (Tue) 9am EDT  — Part 3: The Shopkeeper"
Write-Host "  Apr 16 (Thu) 9am EDT  — Part 4: The Ankh"
Write-Host "  Apr 18 (Sat) 9am EDT  — Part 5: The Becoming"
Write-Host "  Apr 20 (Mon) 9am EDT  — Part 6: Light by the Sea"
Write-Host "  Apr 22 (Wed) 9am EDT  — The Awakening Map (product launch)"
Write-Host ""
Write-Host "REMINDER: Add the cover image to the Awakening Map post (Apr 22) manually in Blotato."
Write-Host "          Go to https://my.blotato.com and edit that post to attach cover_map.png."
