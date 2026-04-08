#!/usr/bin/env bash
# Lumarinne Lifestyle — Blotato Post Scheduler
# Schedules the 8-post Awakening Story series to Instagram and Facebook.
#
# Usage:
#   export BLOTATO_API_KEY=blt_...   (or it reads from env)
#   bash schedule-posts.sh
#
# Prerequisites: curl, jq
#
# Run this script from your local machine (not a sandboxed environment).

set -euo pipefail

API_KEY="${BLOTATO_API_KEY:-}"
BASE_URL="https://backend.blotato.com/v2"

if [[ -z "$API_KEY" ]]; then
  echo "Error: BLOTATO_API_KEY is not set. Export it before running this script."
  exit 1
fi

# ── Step 1: Discover connected accounts ─────────────────────────────────────

echo "Fetching connected social accounts..."
ACCOUNTS=$(curl -sf -X GET "$BASE_URL/users/me/accounts" \
  -H "blotato-api-key: $API_KEY" \
  -H "Content-Type: application/json")

echo "$ACCOUNTS" | jq '.items[] | {id, platform, username}' 2>/dev/null || {
  echo "Raw response: $ACCOUNTS"
  echo "Error: Could not parse accounts. Check your API key."
  exit 1
}

# Pull the first Instagram and Facebook account IDs automatically.
IG_ACCOUNT_ID=$(echo "$ACCOUNTS" | jq -r '.items[] | select(.platform == "instagram") | .id' | head -1)
FB_ACCOUNT_ID=$(echo "$ACCOUNTS" | jq -r '.items[] | select(.platform == "facebook") | .id' | head -1)

echo ""
echo "Instagram account ID : ${IG_ACCOUNT_ID:-not found}"
echo "Facebook account ID  : ${FB_ACCOUNT_ID:-not found}"
echo ""

if [[ -z "$IG_ACCOUNT_ID" && -z "$FB_ACCOUNT_ID" ]]; then
  echo "Error: No Instagram or Facebook accounts found. Connect them at https://my.blotato.com/settings/social-accounts"
  exit 1
fi

# For Facebook pages, get the page ID from subaccounts
FB_PAGE_ID=""
if [[ -n "$FB_ACCOUNT_ID" ]]; then
  SUBACCOUNTS=$(curl -sf -X GET "$BASE_URL/users/me/accounts/$FB_ACCOUNT_ID/subaccounts" \
    -H "blotato-api-key: $API_KEY" \
    -H "Content-Type: application/json" 2>/dev/null || echo '{}')
  FB_PAGE_ID=$(echo "$SUBACCOUNTS" | jq -r '.items[0].pageId // empty' 2>/dev/null | head -1)
fi

# ── Step 2: Define the posting schedule ─────────────────────────────────────
# Day 1 = today, April 8, 2026 at 6 PM EDT (22:00 UTC) — morning has passed.
# Days 3–15 at 9 AM EDT (13:00 UTC). All 2-day cadence as per the content plan.

schedule_post() {
  local platform="$1"
  local account_id="$2"
  local text="$3"
  local scheduled_time="$4"
  local label="$5"
  local page_id="${6:-}"
  local media_urls="${7:-[]}"

  local target_json
  if [[ "$platform" == "facebook" && -n "$page_id" ]]; then
    target_json="{\"targetType\": \"facebook\", \"pageId\": \"$page_id\"}"
  else
    target_json="{\"targetType\": \"$platform\"}"
  fi

  local body
  body=$(jq -n \
    --arg text "$text" \
    --arg platform "$platform" \
    --arg account_id "$account_id" \
    --arg scheduled_time "$scheduled_time" \
    --argjson target "$target_json" \
    --argjson media_urls "$media_urls" \
    '{
      post: {
        accountId: $account_id,
        content: {
          text: $text,
          mediaUrls: $media_urls,
          platform: $platform
        },
        target: $target
      },
      scheduledTime: $scheduled_time
    }')

  local response
  response=$(curl -sf -X POST "$BASE_URL/posts" \
    -H "blotato-api-key: $API_KEY" \
    -H "Content-Type: application/json" \
    -d "$body" 2>&1) && {
    echo "  ✓ Scheduled: $label ($platform)"
  } || {
    echo "  ✗ Failed:    $label ($platform)"
    echo "    Response: $response"
  }
}

echo "Scheduling posts..."
echo ""

# ── Cover image URLs (GitHub raw, pinned to commit SHA) ──────────────────────
IMG_BASE="https://raw.githubusercontent.com/susanne-commits/Notsurewhatthisis/df2e17cb689fea2105afa2b705b9cfaa765a587b/blotato-posts"
IMG_1="[\"$IMG_BASE/cover_1.png\"]"
IMG_2="[\"$IMG_BASE/cover_2.png\"]"
IMG_COUNCIL="[\"$IMG_BASE/cover_council.png\"]"
IMG_3="[\"$IMG_BASE/cover_3.png\"]"
IMG_4="[\"$IMG_BASE/cover_4.png\"]"
IMG_5="[\"$IMG_BASE/cover_5.png\"]"
IMG_6="[\"$IMG_BASE/cover_6.png\"]"
# NOTE: cover_map.png was not uploaded — add the image manually in Blotato after scheduling.
IMG_MAP="[]"

# ── POST 1: Part 1 — The Shattering  (April 13, Monday) ─────────────────────
CAPTION_1="I've never told this story publicly before.

For a long time, I didn't think I was allowed to. It felt too raw. Too real. Too much.

But this is the story of how Lumarinne was born — and it didn't start with a business plan or a product idea. It started with a morning that broke everything.

This is Part 1 of my awakening story. I'll be sharing the full journey over the next two weeks — from the shattering, to the full moon circle on a Spanish beach, to the healers who saw something in me I couldn't see yet, to the woman I became on the other side.

If something in your life is shifting right now, you might see yourself in this story. That's not an accident.

Part 2 drops in 2 days. 🪶

#spiritualawakening #awakeningjourney #lumarinne #awakeningstory #startingover #healingjourney #womenwhoheal #lightworker #newchapter #findingmyself"

[[ -n "$IG_ACCOUNT_ID" ]] && schedule_post "instagram" "$IG_ACCOUNT_ID" "$CAPTION_1" "2026-04-08T22:00:00+00:00" "Part 1 — The Shattering" "" "$IMG_1"
[[ -n "$FB_ACCOUNT_ID" ]] && schedule_post "facebook" "$FB_ACCOUNT_ID" "$CAPTION_1" "2026-04-08T22:00:00+00:00" "Part 1 — The Shattering" "$FB_PAGE_ID" "$IMG_1"

# ── POST 2: Part 2 — The Full Moon  (April 15, Wednesday) ───────────────────
CAPTION_2="The full moon is where it started.

Not the pain — that started before. But the opening. The moment the universe stopped whispering and started speaking directly.

A card was pulled that had never been pulled before. And then it was pulled again.

This is Part 2. If you're new here, start with Part 1 (link in bio).

Part 3 drops in 4 days — and it's the one that gave me chills to write. 🌙

#fullmooncircle #spiritualawakening #counciloflight #lumarinne #awakeningstory #energyhealing #oracledeck #moonritual #healingjourney #divinesigns"

[[ -n "$IG_ACCOUNT_ID" ]] && schedule_post "instagram" "$IG_ACCOUNT_ID" "$CAPTION_2" "2026-04-10T13:00:00+00:00" "Part 2 — The Full Moon" "" "$IMG_2"
[[ -n "$FB_ACCOUNT_ID" ]] && schedule_post "facebook" "$FB_ACCOUNT_ID" "$CAPTION_2" "2026-04-10T13:00:00+00:00" "Part 2 — The Full Moon" "$FB_PAGE_ID" "$IMG_2"

# ── POST 3: Council of Light — Companion Post  (April 17, Friday) ───────────
CAPTION_3="In Part 2 of my story, I told you about the card.

The Council of Light — pulled twice in a row, something that had never happened in my healer's entire practice.

So what does this card actually mean?

The Council of Light represents divine orchestration. It's a message that you have a personal team of helpers in the spiritual realm — ascended masters, light beings, angels, and guides — who are devoted to helping you fulfill your soul's mission.

But here's the part that stopped me: because we live in a world where free will reigns, they cannot help you without your permission. You have to ask.

They can help with anything — nothing is too big or too small. Think of them as your personal team in the spirit realm, ready to step in the moment you invite them.

If you're a lightworker — someone who feels called to uplift others and raise consciousness — the Council of Light is where your personal mission originates.

The activation is simple: place your hands over your heart and say, \"Council of Light, I am ready to receive your help for fulfilling my personal mission. Thank you for guiding me with clarity every step of the way and for sending me helpers and experiences that delight my mind, body, and soul.\"

This card was pulled for me twice. I don't believe that was random. I believe it was an invitation — and I accepted it.

If you're reading this and something in you just lit up, that's not an accident either. 🪶

#counciloflight #lightworker #spiritualguidance #oraclecards #divineorchestration #lumarinne #awakeningstory #spiritguides #angels #ascendedmasters"

[[ -n "$IG_ACCOUNT_ID" ]] && schedule_post "instagram" "$IG_ACCOUNT_ID" "$CAPTION_3" "2026-04-12T13:00:00+00:00" "Council of Light" "" "$IMG_COUNCIL"
[[ -n "$FB_ACCOUNT_ID" ]] && schedule_post "facebook" "$FB_ACCOUNT_ID" "$CAPTION_3" "2026-04-12T13:00:00+00:00" "Council of Light" "$FB_PAGE_ID" "$IMG_COUNCIL"

# ── POST 4: Part 3 — The Shopkeeper  (April 19, Sunday) ─────────────────────
CAPTION_4="This is the part of the story that still gives me chills.

A woman in a tiny crystal shop in a Spanish village. She didn't speak my language. Her daughter translated over speakerphone. She insisted on reading my cards for free because she said she felt something the moment I walked in.

I don't know her name. I never learned it. But she saw something in me that I was only just beginning to see in myself.

Part 3 of my awakening story. Start from Part 1 if you're new (link in bio). 🪶

#synchronicity #crystalshop #tarotreading #spiritualawakening #lumarinne #awakeningstory #divinesigns #spain #healingjourney #trusttheuniverse"

[[ -n "$IG_ACCOUNT_ID" ]] && schedule_post "instagram" "$IG_ACCOUNT_ID" "$CAPTION_4" "2026-04-14T13:00:00+00:00" "Part 3 — The Shopkeeper" "" "$IMG_3"
[[ -n "$FB_ACCOUNT_ID" ]] && schedule_post "facebook" "$FB_ACCOUNT_ID" "$CAPTION_4" "2026-04-14T13:00:00+00:00" "Part 3 — The Shopkeeper" "$FB_PAGE_ID" "$IMG_3"

# ── POST 5: Part 4 — The Ankh  (April 21, Tuesday) ──────────────────────────
CAPTION_5="\"You are very protected.\"

Those four words changed how I understood everything that had happened to me.

The voice that told me to go talk to my son. The full moon that pulled me to the beach. The card that had never been pulled. The shopkeeper who saw me before I saw myself.

I wasn't just stumbling through an awakening. I was being guided through one.

Part 4. The ankh. The energy. And the woman who confirmed it all on my last night in Spain. 🪶

#reiki #ankh #energyhealing #rootchakra #spiritualprotection #lumarinne #awakeningstory #youareprotected #healingjourney #divineenergy"

[[ -n "$IG_ACCOUNT_ID" ]] && schedule_post "instagram" "$IG_ACCOUNT_ID" "$CAPTION_5" "2026-04-16T13:00:00+00:00" "Part 4 — The Ankh" "" "$IMG_4"
[[ -n "$FB_ACCOUNT_ID" ]] && schedule_post "facebook" "$FB_ACCOUNT_ID" "$CAPTION_5" "2026-04-16T13:00:00+00:00" "Part 4 — The Ankh" "$FB_PAGE_ID" "$IMG_4"

# ── POST 6: Part 5 — The Becoming  (April 23, Thursday) ─────────────────────
CAPTION_6="This was the quiet part of the awakening. No healers. No cards. No sessions.

Just me, a journal, and five months of learning who I am without all the roles attached.

I am pretty much alone now. But I am not lonely. There is a difference the size of a universe between those two things.

Part 5. The becoming. 🪶

#becomingher #solitude #spiritualawakening #lumarinne #awakeningstory #lettinggo #newchapter #startingover #womenover40 #selfreclamation"

[[ -n "$IG_ACCOUNT_ID" ]] && schedule_post "instagram" "$IG_ACCOUNT_ID" "$CAPTION_6" "2026-04-18T13:00:00+00:00" "Part 5 — The Becoming" "" "$IMG_5"
[[ -n "$FB_ACCOUNT_ID" ]] && schedule_post "facebook" "$FB_ACCOUNT_ID" "$CAPTION_6" "2026-04-18T13:00:00+00:00" "Part 5 — The Becoming" "$FB_PAGE_ID" "$IMG_5"

# ── POST 7: Part 6 — Light by the Sea  (April 25, Saturday) ─────────────────
CAPTION_7="Luma: light. Marinne: the sea.

Born under the full moon, by the Mediterranean, in the middle of starting over.

This is Part 6. The final chapter — for now.

Thank you for reading this story. Thank you for being here. If any part of it made you feel seen, that's exactly why I wrote it.

I made a guide for women who are going through what I went through. It's called The Awakening Map. Link in bio. 🪶

#lumarinne #lightbythesea #awakeningstory #spiritualawakening #brandstory #womenwhoheal #startingover #italy #newbeginnings #awakeish"

[[ -n "$IG_ACCOUNT_ID" ]] && schedule_post "instagram" "$IG_ACCOUNT_ID" "$CAPTION_7" "2026-04-20T13:00:00+00:00" "Part 6 — Light by the Sea" "" "$IMG_6"
[[ -n "$FB_ACCOUNT_ID" ]] && schedule_post "facebook" "$FB_ACCOUNT_ID" "$CAPTION_7" "2026-04-20T13:00:00+00:00" "Part 6 — Light by the Sea" "$FB_PAGE_ID" "$IMG_6"

# ── POST 8: The Awakening Map — Product Launch  (April 27, Monday) ───────────
CAPTION_8="When everything was happening to me in Spain — the full moon circles, the energy work, the cards, the signs — I kept searching for something that would tell me I wasn't crazy.

I googled \"spiritual awakening\" at 2am. I asked healers. I asked AI. I was looking for a guide that would say: this is real, this is what's happening, here's what comes next.

I never found it. So I built it.

The Awakening Map is a guided journal for women who are waking up and want to know they're not losing their minds.

Six stages. Education, journal prompts, and practical tools for each one. Written by a woman who went through it and documented it in real time — not by a guru looking backward.

This is designed to be printed and written in by hand. There is something about the connection between your brain, your eyes, and your hands — the physical act of writing — that helps your body process and release what your mind is holding. That's not an afterthought. It's by design.

\$22.22 — because in the language of angel numbers, 2222 represents alignment, trust, and divine timing. The very things this journal was built to help you find.

Link in bio. 🪶

#theawakeningmap #lumarinne #awakenishjournal #spiritualawakening #guidedjournal #womenwhoheal #awakeish #healingtools #journaling #awakeningstages"

# IMG_MAP is empty — add cover_map.png manually in Blotato after scheduling.
[[ -n "$IG_ACCOUNT_ID" ]] && schedule_post "instagram" "$IG_ACCOUNT_ID" "$CAPTION_8" "2026-04-22T13:00:00+00:00" "Awakening Map — Product Launch" "" "$IMG_MAP"
[[ -n "$FB_ACCOUNT_ID" ]] && schedule_post "facebook" "$FB_ACCOUNT_ID" "$CAPTION_8" "2026-04-22T13:00:00+00:00" "Awakening Map — Product Launch" "$FB_PAGE_ID" "$IMG_MAP"

# ── Done ─────────────────────────────────────────────────────────────────────
echo ""
echo "Done. View your scheduled posts at https://my.blotato.com"
echo ""
echo "Schedule:"
echo "  Apr 8  (Wed) 6pm EDT — Part 1: The Shattering"
echo "  Apr 10 (Fri) 9am EDT — Part 2: The Full Moon"
echo "  Apr 12 (Sun) 9am EDT — Council of Light (companion)"
echo "  Apr 14 (Tue) 9am EDT — Part 3: The Shopkeeper"
echo "  Apr 16 (Thu) 9am EDT — Part 4: The Ankh"
echo "  Apr 18 (Sat) 9am EDT — Part 5: The Becoming"
echo "  Apr 20 (Mon) 9am EDT — Part 6: Light by the Sea"
echo "  Apr 22 (Wed) 9am EDT — The Awakening Map (product launch)"
echo ""
echo "NOTE: Add carousel images to Instagram posts in the Blotato queue."
echo "      See brand/content-samples/awakening-story-social-media-package.md"
echo "      for the photo guide and slide copy."
