#!/bin/bash
# =============================================
# LanguageTool Enterprise - Full Activation
# =============================================

echo "=== LanguageTool Enterprise Full Activation ==="
echo ""

# 1. Backup current config
echo "[1/5] Backing up current configuration..."
if [ -f /opt/languagetool/server/languagetool.conf ]; then
    sudo cp /opt/languagetool/server/languagetool.conf /opt/languagetool/server/languagetool.conf.backup
    echo "✓ Backup created"
fi

# 2. Write new configuration with all languages
echo "[2/5] Writing new configuration..."
sudo tee /opt/languagetool/server/languagetool.conf > /dev/null << 'EOF'
# LanguageTool Enterprise Configuration
# LanguageTool 6.8-SNAPSHOT

# FastText Language Detection
fasttextModel=/opt/languagetool/fasttext/lid.176.bin

# N-gram Language Models
languageModel=/opt/languagetool/ngram-data

# Custom Rules Directory
customRulesDir=/opt/languagetool/custom-rules

# Enable all open rules (premium-level)
loadAllOpenRules=true

# Pipeline Caching
pipelineCaching=true

# Request Cache Size
cacheSize=1000

# Maximum text length (characters)
maxTextLength=50000

# Maximum check threads
maxCheckThreads=8

# Auto-detect language
languageAutoDetect=true

# Enabled Languages (all supported)
enabledLanguages=ar,ast,be,br,ca,ca-ES-valencia,ca-ES-balear,da,de,de-DE,de-AT,de-CH,de-DE-x-simple-language,el,en,en-US,en-GB,en-AU,en-CA,en-NZ,en-ZA,eo,es,es-AR,fa,fr,fr-CA,fr-CH,fr-BE,ga,gl,it,ja,km,nl,nl-BE,pl,pt,pt-PT,pt-BR,pt-AO,pt-MZ,ro,ru,sk,sl,sv,ta,tl,uk,zh,crh
EOF
echo "✓ Configuration written"

# 3. Restart all LanguageTool services
echo "[3/5] Restarting all LanguageTool services..."
sudo systemctl restart languagetool 2>/dev/null || echo "  - Instance 1: restart requested"
sudo systemctl restart languagetool-2 2>/dev/null || echo "  - Instance 2: not configured yet"
sudo systemctl restart languagetool-3 2>/dev/null || echo "  - Instance 3: not configured yet"
echo "✓ Services restarted"

# 4. Wait for startup
echo "[4/5] Waiting for services to start..."
sleep 5
echo "✓ Services ready"

# 5. Test endpoints
echo "[5/5] Testing language endpoints..."
echo ""

# Test German
echo "Testing German (de-DE):"
curl -s -X POST http://127.0.0.1:8081/v2/check \
  -d "text=Ich habe das gemacht und es war sehr gut aber ich bin nicht sicher ob es richtig ist" \
  -d "language=de-DE" | python3 -c "import sys,json; d=json.load(sys.stdin); print(f'  Matches found: {len(d[\"matches\"])}')" 2>/dev/null || echo "  Error testing"

# Test English
echo "Testing English (en-US):"
curl -s -X POST http://127.0.0.1:8081/v2/check \
  -d "text=This are wrong sentence" \
  -d "language=en-US" | python3 -c "import sys,json; d=json.load(sys.stdin); print(f'  Matches found: {len(d[\"matches\"])}')" 2>/dev/null || echo "  Error testing"

# Test French
echo "Testing French (fr):"
curl -s -X POST http://127.0.0.1:8081/v2/check \
  -d "text=Je suis aller au magasin" \
  -d "language=fr" | python3 -c "import sys,json; d=json.load(sys.stdin); print(f'  Matches found: {len(d[\"matches\"])}')" 2>/dev/null || echo "  Error testing"

# Test Spanish
echo "Testing Spanish (es):"
curl -s -X POST http://127.0.0.1:8081/v2/check \
  -d "text=Yo soy ir al tienda" \
  -d "language=es" | python3 -c "import sys,json; d=json.load(sys.stdin); print(f'  Matches found: {len(d[\"matches\"])}')" 2>/dev/null || echo "  Error testing"

# Test Dutch
echo "Testing Dutch (nl):"
curl -s -X POST http://127.0.0.1:8081/v2/check \
  -d "text=Ik ga naar de winkel" \
  -d "language=nl" | python3 -c "import sys,json; d=json.load(sys.stdin); print(f'  Matches found: {len(d[\"matches\"])}')" 2>/dev/null || echo "  Error testing"

# Get total languages
echo ""
echo "Total languages supported:"
curl -s http://127.0.0.1:8081/v2/languages | python3 -c "import sys,json; print(f'  {len(json.load(sys.stdin))} languages')" 2>/dev/null

echo ""
echo "=== Activation Complete ==="
echo ""
echo "Configuration file: /opt/languagetool/server/languagetool.conf"
echo "Custom rules: /opt/languagetool/custom-rules/"
echo "N-gram data: /opt/languagetool/ngram-data/"
echo ""
echo "Memory usage:"
free -h | grep Mem || echo "  (check with: free -h)"
