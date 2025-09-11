#!/bin/bash
set +e

mkdir -p battle_logs

# Monta a configuração da batalha
cat > battle_logs/sample_vs_sample.battle <<EOF
robocode.battleField.width=800
robocode.battleField.height=600
robocode.battle.numRounds=3
robocode.battle.gunCoolingRate=0.1
robocode.battle.rules.inactivityTime=450
robocode.battle.hideEnemyNames=false
robocode.battle.robots=github.Corners,github.PrimeiroRobo
EOF

echo "Rodando batalha entre os robôs github.Corners e github.PrimeiroRobo..."
java -Xmx512M -cp libs/robocode.jar robocode.Robocode -battle battle_logs/sample_vs_sample.battle -nodisplay > battle_logs/sample_result.txt 2>&1 || true

# Lê os status
STATUS_CHECKSTYLE=$(cat battle_logs/checkstyle_status.txt 2>/dev/null || echo "N/A")
STATUS_SPOTBUGS=$(cat battle_logs/spotbugs_status.txt 2>/dev/null || echo "N/A")
STATUS_COMPILE=$(cat battle_logs/robocode_build_status.txt 2>/dev/null || echo "N/A")

# Interpreta status para HTML
html_interpreta() {
  if [[ "$1" == "0" ]]; then
    echo "<span style='color:green;font-weight:bold'>✅ Sucesso</span> <span style='color:gray'>(0)</span>"
  elif [[ "$1" == "1" ]]; then
    echo "<span style='color:#e6bc01;font-weight:bold'>⚠️ Erro menor</span> <span style='color:gray'>(1)</span>"
  elif [[ "$1" == "N/A" ]]; then
    echo "<span style='color:gray'>❔ Não disponível</span>"
  else
    echo "<span style='color:red;font-weight:bold'>❌ Falhou</span> <span style='color:gray'>($1)</span>"
  fi
}

# Monta relatório HTML
REPORT_HTML="battle_logs/report.html"
cat > "$REPORT_HTML" <<EOF
<!DOCTYPE html>
<html lang="pt-br">
<head>
  <meta charset="UTF-8">
  <title>Relatório Robocode Pipeline</title>
  <style>
    body { font-family: 'Segoe UI', Arial, sans-serif; background: #fafbfc; margin:0; padding:32px; }
    h1, h2, h3 { color: #2a2a2a; }
    table { border-collapse:collapse; width:550px; margin-bottom:24px; }
    th, td { border: 1px solid #c0c0c0; padding:8px 16px; text-align: left; font-size: 18px; }
    th { background-color: #f3f4f6; }
    code, pre { font-family: 'Fira Mono', 'Consolas', monospace; background: #eaeaea; border-radius: 6px; }
    small { color:#666; }
    footer { margin-top: 32px; font-size: 14px; color: #444; text-align: center; border-top: 1px solid #ccc; padding-top: 12px; }
  </style>
</head>
<body>
  <h1>Relatório do Pipeline Robocode</h1>
  <table>
    <tr><th>Etapa</th><th>Status</th></tr>
    <tr><td><b>Checkstyle</b></td>          <td>$(html_interpreta "$STATUS_CHECKSTYLE")</td></tr>
    <tr><td><b>SpotBugs</b></td>            <td>$(html_interpreta "$STATUS_SPOTBUGS")</td></tr>
    <tr><td><b>Compilação Robocode</b></td> <td>$(html_interpreta "$STATUS_COMPILE")</td></tr>
  </table>
  <h2>Log da Batalha</h2>
  <pre>
EOF

grep -E "github.Corners|github.PrimeiroRobo" battle_logs/sample_result.txt | head -40 >> "$REPORT_HTML"

WINNER=$(grep -A 10 "Battle Results" battle_logs/sample_result.txt | grep -m1 "1st" | awk '{print $2}')

cat >> "$REPORT_HTML" <<EOF
  </pre>
  <h2>Resultado Final</h2>
  <p><b>Vencedor:</b> $WINNER</p>
  <footer>
    Relatório gerado automaticamente em $(date '+%d/%m/%Y %H:%M') <br>
    © Otávio Augusto Monteiro Discini — Todos os direitos reservados
  </footer>
</body>
</html>
EOF

echo "Relatório HTML gerado em $REPORT_HTML"
exit 0