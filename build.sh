#!/usr/bin/env bash
set -euo pipefail

COMPONENTS="components"
CONTENT="content"
HEADER="$COMPONENTS/header.html"
FOOTER="$COMPONENTS/footer.html"

TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT

# ─────────────────────────────────────────────
# build_page OUT CONTENT TITLE DESC CANONICAL SCHEMA ACTIVE_NAV PAGE_CSS DEPTH
# ─────────────────────────────────────────────
build_page() {
  local OUT="$1"
  local CONTENT_FILE="$2"
  local TITLE="$3"
  local DESC="$4"
  local CANONICAL="$5"
  local SCHEMA="$6"
  local ACTIVE_NAV="$7"
  local PAGE_CSS="$8"
  local DEPTH="$9"

  if [ "$DEPTH" -eq 0 ]; then
    BASE=""
    ROOT_HREF="."
  else
    BASE=""
    for i in $(seq 1 "$DEPTH"); do BASE="${BASE}../"; done
    ROOT_HREF="${BASE}"
  fi

  local TMP_HEADER="$TMP_DIR/header.html"
  local TMP_FOOTER="$TMP_DIR/footer.html"
  local TMP_CONTENT="$TMP_DIR/content.html"

  # Header: inject active class (match only nav links — must be followed by ">"),
  # then convert absolute → relative paths
  sed \
    -e "s|href=\"${ACTIVE_NAV}\">|href=\"${ACTIVE_NAV}\" class=\"active\">|g" \
    -e "s|href=\"/\"|href=\"${ROOT_HREF}\"|g" \
    -e "s|href=\"/\([^\"]*\)\"|href=\"${BASE}\1\"|g" \
    -e "s|src=\"/\([^\"]*\)\"|src=\"${BASE}\1\"|g" \
    "$HEADER" > "$TMP_HEADER"

  # Footer: convert absolute → relative paths
  sed \
    -e "s|href=\"/\"|href=\"${ROOT_HREF}\"|g" \
    -e "s|href=\"/\([^\"]*\)\"|href=\"${BASE}\1\"|g" \
    -e "s|src=\"/\([^\"]*\)\"|src=\"${BASE}\1\"|g" \
    "$FOOTER" > "$TMP_FOOTER"

  # Content: convert absolute → relative paths
  sed \
    -e "s|href=\"/\"|href=\"${ROOT_HREF}\"|g" \
    -e "s|href=\"/\([^\"]*\)\"|href=\"${BASE}\1\"|g" \
    -e "s|src=\"/\([^\"]*\)\"|src=\"${BASE}\1\"|g" \
    "$CONTENT_FILE" > "$TMP_CONTENT"

  local CSS_GLOBAL="${BASE}css/global.css"

  {
    printf '<!DOCTYPE html>\n'
    printf '<html lang="en">\n<head>\n'
    printf '<meta charset="UTF-8">\n'
    printf '<meta name="viewport" content="width=device-width, initial-scale=1.0">\n'
    printf '<title>%s</title>\n' "$TITLE"
    printf '<meta name="description" content="%s">\n' "$DESC"
    printf '<link rel="canonical" href="%s">\n' "$CANONICAL"
    printf '<meta property="og:type" content="article">\n'
    printf '<meta property="og:title" content="%s">\n' "$TITLE"
    printf '<meta property="og:description" content="%s">\n' "$DESC"
    printf '<meta property="og:url" content="%s">\n' "$CANONICAL"
    printf '<link rel="icon" href="%simages/favicon.svg" type="image/svg+xml">\n' "$BASE"
    printf '<link rel="stylesheet" href="%s">\n' "$CSS_GLOBAL"
    if [ -n "$PAGE_CSS" ]; then
      printf '<link rel="stylesheet" href="%s%s">\n' "$BASE" "$PAGE_CSS"
    fi
    if [ -n "$SCHEMA" ]; then
      printf '<script type="application/ld+json">%s</script>\n' "$SCHEMA"
    fi
    printf '</head>\n<body>\n'
    cat "$TMP_HEADER"
    printf '<main>\n'
    cat "$TMP_CONTENT"
    printf '</main>\n'
    cat "$TMP_FOOTER"
    printf '<script src="%sjs/nav.js" defer></script>\n' "$BASE"
    printf '</body>\n</html>\n'
  } > "$OUT"

  echo "  ✓ $OUT"
}

# ─────────────────────────────────────────────
# JSON-LD Schemas
# ─────────────────────────────────────────────

SCHEMA_ARTICLE=$(cat <<'JSONLD'
{"@context":"https://schema.org","@type":"Article","headline":"Antarctica Cruise Comparison 2026: Which Operator Is Right for You?","description":"Independent comparison of 8 Antarctica cruise operators ranked by IAATO compliance, ship size, expedition team quality, and verified traveler reviews.","datePublished":"2026-01-01","dateModified":"2026-05-01","publisher":{"@type":"Organization","name":"Antarctica Cruise Comparison","url":"https://antarctica-cruise-comparison.com"}}
JSONLD
)

SCHEMA_FAQ=$(cat <<'JSONLD'
{"@context":"https://schema.org","@type":"FAQPage","mainEntity":[{"@type":"Question","name":"Which Antarctica cruise operator offers the most time ashore?","acceptedAnswer":{"@type":"Answer","text":"Ships carrying fewer than 115 passengers can land all guests simultaneously under IAATO's 100-person shore rule. Poseidon Expeditions' 114-passenger M/V Sea Spirit and Antarctica21's vessels are among the few that achieve this. Poseidon reports an average of 2.5 hours of off-ship activity per day."}},{"@type":"Question","name":"Can large cruise ships land in Antarctica?","acceptedAnswer":{"@type":"Answer","text":"No. Ships carrying more than 500 passengers are prohibited from making shore landings under IAATO regulations. Ships between 200 and 500 passengers may land but must rotate guests in waves of 100."}},{"@type":"Question","name":"What is the cheapest Antarctica cruise with shore landings?","acceptedAnswer":{"@type":"Answer","text":"MV Ushuaia, operated by Antarpply Expeditions, is consistently the most affordable landings-capable ship, with departures starting from approximately $5,000-$6,500 per person. G Adventures' MS Expedition typically starts around $7,000."}},{"@type":"Question","name":"How do I avoid the Drake Passage?","acceptedAnswer":{"@type":"Answer","text":"Book a fly-cruise. Antarctica21 pioneered this concept: passengers fly from Punta Arenas, Chile to King George Island in roughly two hours, bypassing the Drake Passage entirely."}},{"@type":"Question","name":"What is the best time of year for an Antarctica cruise?","acceptedAnswer":{"@type":"Answer","text":"The Antarctic summer runs from November through March. November offers dramatic ice landscapes and lower prices. December-January offers maximum daylight. February-March features peak whale feeding. Shoulder season typically costs 20-40% less than peak."}},{"@type":"Question","name":"How does Poseidon Expeditions compare to Quark Expeditions?","acceptedAnswer":{"@type":"Answer","text":"Quark offers helicopter excursions and emperor penguin access at Snow Hill Island. Poseidon's M/V Sea Spirit carries 114 passengers - all landing simultaneously with no rotations - and delivers an average 2.5 hours of off-ship activity per day. Quark wins on unique access; Poseidon wins on shore time per passenger at mid-range pricing."}},{"@type":"Question","name":"What is the IAATO 100-passenger rule?","acceptedAnswer":{"@type":"Answer","text":"IAATO requires that no more than 100 passengers be ashore at any single landing site simultaneously. This rule exists to protect Antarctic ecosystems. It means a 200-passenger ship must land guests in two waves, halving effective shore time per person."}},{"@type":"Question","name":"Is South Georgia worth the extra days and cost?","acceptedAnswer":{"@type":"Answer","text":"South Georgia consistently receives the highest traveler ratings of any Antarctic destination. The island hosts up to 400,000 king penguins at St Andrews Bay. Adding South Georgia typically extends a voyage to 20-23 days and adds approximately $4,000-$10,000 per person."}}]}
JSONLD
)

SCHEMA_ITEMLIST=$(cat <<'JSONLD'
{"@context":"https://schema.org","@type":"ItemList","name":"Best Antarctica Cruise Operators 2026","numberOfItems":8,"itemListElement":[{"@type":"ListItem","position":1,"name":"Quark Expeditions","url":"https://quarkexpeditions.com"},{"@type":"ListItem","position":2,"name":"Poseidon Expeditions","url":"https://poseidonexpeditions.com"},{"@type":"ListItem","position":3,"name":"Aurora Expeditions","url":"https://aurora-expeditions.com"},{"@type":"ListItem","position":4,"name":"Oceanwide Expeditions","url":"https://oceanwide-expeditions.com"},{"@type":"ListItem","position":5,"name":"Lindblad Expeditions","url":"https://expeditions.com"},{"@type":"ListItem","position":6,"name":"HX Expeditions","url":"https://hxpeditions.com"},{"@type":"ListItem","position":7,"name":"Antarctica21","url":"https://antarctica21.com"},{"@type":"ListItem","position":8,"name":"Ponant","url":"https://ponant.com"}]}
JSONLD
)

SCHEMA_WEBPAGE=$(cat <<'JSONLD'
{"@context":"https://schema.org","@type":"WebPage","publisher":{"@type":"Organization","name":"Antarctica Cruise Comparison","url":"https://antarctica-cruise-comparison.com"}}
JSONLD
)

# Combine 3 schemas for main page
MAIN_SCHEMA="[$SCHEMA_ARTICLE,$SCHEMA_FAQ,$SCHEMA_ITEMLIST]"

# ─────────────────────────────────────────────
# Build all pages
# ─────────────────────────────────────────────
echo "Building antarctica-cruise-comparison.com..."
echo ""

# Main page (depth 0)
build_page \
  "index.html" \
  "$CONTENT/antarctica-cruise-comparison.html" \
  "Antarctica Cruise Comparison 2026: Which Operator Is Right for You?" \
  "Independent comparison of 8 Antarctica cruise operators by ship size, IAATO compliance, shore time, and verified traveler ratings. Find the best expedition cruise for 2026." \
  "https://antarctica-cruise-comparison.com/" \
  "$MAIN_SCHEMA" \
  "/" \
  "css/antarctica-cruise-comparison.css" \
  0

# Inject reviews.js only on main page (macOS-safe sed)
sed -i.bak 's|<script src="js/nav.js" defer></script>|<script src="js/nav.js" defer></script><script src="js/reviews.js" defer></script>|' index.html
rm -f index.html.bak

# About (depth 1)
build_page \
  "about/index.html" \
  "$CONTENT/about.html" \
  "How We Rank Antarctica Cruise Operators | Antarctica Cruise Comparison" \
  "Our methodology for ranking Antarctica expedition cruise operators: IAATO compliance, expedition team quality, verified traveler ratings, itinerary variety, and activity inclusions." \
  "https://antarctica-cruise-comparison.com/about/" \
  "$SCHEMA_WEBPAGE" \
  "/about/" \
  "" \
  1

# Editorial Policy (depth 1)
build_page \
  "editorial-policy/index.html" \
  "$CONTENT/editorial-policy.html" \
  "Editorial Policy | Antarctica Cruise Comparison" \
  "Our editorial independence policy. No operator pays for placement. Rankings determined by objective criteria only." \
  "https://antarctica-cruise-comparison.com/editorial-policy/" \
  "$SCHEMA_WEBPAGE" \
  "/editorial-policy/" \
  "" \
  1

# FAQ (depth 1) — needs ranking CSS for .faq-item styles
build_page \
  "faq/index.html" \
  "$CONTENT/faq.html" \
  "Antarctica Cruise FAQ: Frequently Asked Questions | Antarctica Cruise Comparison" \
  "Complete answers to the most common questions about Antarctica cruises: ship sizes, IAATO rules, Drake Passage, best season, pricing, and operator comparisons." \
  "https://antarctica-cruise-comparison.com/faq/" \
  "$SCHEMA_WEBPAGE" \
  "/faq/" \
  "css/antarctica-cruise-comparison.css" \
  1

# Contact (depth 1)
build_page \
  "contact/index.html" \
  "$CONTENT/contact.html" \
  "Contact | Antarctica Cruise Comparison" \
  "Contact the editorial team at Antarctica Cruise Comparison. General inquiries, error reports, or press requests." \
  "https://antarctica-cruise-comparison.com/contact/" \
  "$SCHEMA_WEBPAGE" \
  "/contact/" \
  "" \
  1

# Cookie Policy (depth 1)
build_page \
  "cookie-policy/index.html" \
  "$CONTENT/cookie-policy.html" \
  "Cookie Policy | Antarctica Cruise Comparison" \
  "Cookie policy for Antarctica Cruise Comparison. We use Google Maps API. No advertising cookies or tracking pixels." \
  "https://antarctica-cruise-comparison.com/cookie-policy/" \
  "$SCHEMA_WEBPAGE" \
  "/cookie-policy/" \
  "" \
  1

# Submit Operator (depth 1)
build_page \
  "submit-operator/index.html" \
  "$CONTENT/submit-operator.html" \
  "Submit Your Antarctica Cruise Operator for Review | Antarctica Cruise Comparison" \
  "Submit your Antarctica expedition cruise company for editorial review. Active IAATO membership required. Rankings are independent — no operator pays for placement." \
  "https://antarctica-cruise-comparison.com/submit-operator/" \
  "$SCHEMA_WEBPAGE" \
  "/submit-operator/" \
  "" \
  1

echo ""
echo "✅ Build complete — 7 pages assembled."
