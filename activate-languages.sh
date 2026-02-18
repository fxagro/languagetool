#!/bin/bash
# =============================================
# LanguageTool Enterprise - Activate All Languages
# =============================================

# Folder config
LT_CONF="/opt/languagetool/server/languagetool.conf"
CUSTOM_RULES="/opt/languagetool/custom-rules"

echo "=== Activating all languages ==="

# 1. Tambahkan semua bahasa di config
echo "enabledLanguages=ar,ast,be,br,ca,da,de,en,eo,es,fa,fr,ga,gl,it,ja,km,nl,pl,pt,ro,ru,sk,sl,sv,ta,tl,uk,zh,crh" | sudo tee -a $LT_CONF

# 2. Aktifkan load rules semua
echo "loadAllOpenRules=true" | sudo tee -a $LT_CONF
echo "loadPremiumRules=true" | sudo tee -a $LT_CONF
echo "customRulesDir=$CUSTOM_RULES" | sudo tee -a $LT_CONF

# 3. Restart semua service LT
echo "=== Restarting LanguageTool instances ==="
sudo systemctl restart languagetool
sudo systemctl restart languagetool-2
sudo systemctl restart languagetool-3

# 4. Test server
echo "=== Testing German endpoint ==="
curl -X POST http://127.0.0.1:8081/v2/check \
  -d "text=Gestern ich gehe zu die Büro und treffe meine Chef." \
  -d "language=de-DE"
echo
echo "=== Done. All languages activated ==="
