#!/usr/bin/env bash
# SessionStart hook: Claude Code 웹 세션이 깨끗한 상태에서 시작될 때
# PaperMod 테마(서브모듈)를 초기화하고 git 사용자 정보를 보장한다.
# stdout 출력은 Claude의 세션 컨텍스트로 전달된다.

set -e

echo "[SessionStart] nansu0425.github.io blog setup..."

# 1) PaperMod 서브모듈이 비어 있으면 초기화
if [ ! -f themes/PaperMod/theme.toml ] && [ ! -f themes/PaperMod/layouts/_default/baseof.html ]; then
  echo "[SessionStart] Initializing PaperMod submodule..."
  git submodule update --init --recursive 2>&1 || echo "[SessionStart] submodule init failed (non-fatal)"
else
  echo "[SessionStart] PaperMod theme present."
fi

# 2) git user 정보가 없으면 기본값 설정 (커밋 가능하도록)
if [ -z "$(git config user.email 2>/dev/null)" ]; then
  git config user.email "claude@anthropic.com"
  echo "[SessionStart] git user.email set to claude@anthropic.com"
fi
if [ -z "$(git config user.name 2>/dev/null)" ]; then
  git config user.name "nansu0425"
  echo "[SessionStart] git user.name set to nansu0425"
fi

# 3) 안내
echo "[SessionStart] Ready. Use /new-post <title> to scaffold a draft post."
echo "[SessionStart] See CLAUDE.md for blog conventions and the draft workflow."
