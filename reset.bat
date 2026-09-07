@echo off
setlocal
chcp 65001 >nul

set "A2A_API=http://127.0.0.1:8088"
echo =====================================================
echo 悟空平台数据复位
echo 将清空：模型配置、智能体、MCP、Skill、知识库、军团编排和上线状态
echo 不会清空：蜜罐报告、攻击证据和配置文件
echo =====================================================
choice /C YN /N /M "确认继续？[Y/N]: "
if errorlevel 2 exit /b 0

curl.exe -fsS -X POST "%A2A_API%/api/v1/system/reset" -H "Content-Type: application/json" --data "{\"password\":\"admin\"}"
if errorlevel 1 (
  echo.
  echo 复位失败，请确认 Go 后端已在 8088 端口启动。
  pause
  exit /b 1
)

echo.
echo 复位完成。刷新浏览器后平台将回到初始空状态。
pause
endlocal
