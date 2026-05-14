---
description: 새 블로그 포스트를 draft 상태로 생성합니다 (Hugo + PaperMod)
argument-hint: <포스트 제목>
---

당신은 nansu0425의 Hugo 블로그(`content/posts/`)에 새 포스트를 생성합니다. 사용자가 입력한 제목: **$ARGUMENTS**

## 절차

### 1. Slug 생성

제목 `$ARGUMENTS`를 파일명으로 변환:
- 공백 → 하이픈(`-`)
- 한국어는 그대로 유지 (예: "FPS 카메라를 위한 회전 행렬 곱 순서" → `FPS-카메라를-위한-회전-행렬-곱-순서`)
- 슬래시(`/`), 콜론(`:`), 따옴표 등 파일 시스템 위험 문자는 제거 또는 하이픈 치환
- 결과 경로: `content/posts/<slug>.md`

이미 같은 파일이 존재하면 사용자에게 알리고 중단.

### 2. 메타데이터 수집

`AskUserQuestion` 도구로 다음을 한 번에 물어본 뒤 frontmatter 채우기:

- **카테고리** (단일): 기존 포스트에서 쓰인 값 — `Graphics`, `C++`, `Algorithm`, `Math`, `Game Development` 중 선택 또는 직접 입력
- **태그** (다중 선택): 자유 입력. 예시 — `graphics`, `math`, `linear-algebra`, `algorithm`, `cpp`, `game-dev`
- **수식 사용 여부** (`math: true/false`): KaTeX 로드. 수식이 없으면 `false`로 두어 페이지 무게 줄임
- **TikZ 사용 여부** (`tikz: true/false`): TikZJax 로드. 다이어그램이 없으면 `false`

요약(summary)과 설명(description)은 본문 작성 전이므로 사용자가 입력하지 않아도 되도록 **임시 placeholder**(예: `"TODO: 한 줄 요약"`)로 두고, 본문 작성 후 채우도록 안내.

### 3. 파일 생성

다음 frontmatter + 본문 골격으로 파일을 만든다 (오늘 날짜 사용):

```markdown
---
title: "$ARGUMENTS"
date: <YYYY-MM-DD (오늘)>
tags: [<수집한 태그>]
categories: ["<수집한 카테고리>"]
summary: "TODO: 한 줄 요약"
description: "TODO: 검색 엔진과 SNS 공유에 쓰일 1~2문장 설명"
math: <true/false>
tikz: <true/false>
draft: true
---

## 문제

TODO: 이 글을 쓰는 이유, 해결하려는 질문이나 현상

## 배경

TODO: 독자가 알아야 할 전제, 규약, 정의

## 본론

TODO: 핵심 내용 — 단계별로 ## 소제목을 추가하며 전개

## 요약

TODO: 핵심 결론을 글머리 기호로 정리
```

오늘 날짜는 환경 컨텍스트의 `currentDate`를 사용 (예: 2026-05-14 → `date: 2026-05-14`).

### 4. 안내

파일 생성 후 사용자에게:
- 생성된 경로 (`content/posts/<slug>.md`)
- "draft 상태이므로 main에 바로 푸시해도 사이트엔 노출되지 않습니다"
- "본문을 작성하시고, 마지막에 summary/description을 채워주세요. 공개 준비가 되면 `draft: false`로 바꾸면 됩니다"
- 다음 단계 제안: "본문을 함께 작성할까요? 어떤 내용을 다룰지 알려주세요."

## 참고 — 기존 포스트 패턴

본문 골격을 변형하거나 사용자가 다른 구조를 원할 때 다음 두 포스트의 구조를 참고:
- `content/posts/FPS-카메라를-위한-회전-행렬-곱-순서.md` — 문제 → 배경 규약 → 핵심 명제 → 수식 증명 → 구체 예시 → 적용 → 요약
- `content/posts/2D-점이-삼각형-내부에-있는지-판정하는-방법.md` — 알고리즘 정의 → cross product 부호 분석 → 구현 예시

## 주의

- frontmatter는 YAML이므로 들여쓰기·따옴표 정확히
- 태그·카테고리 배열은 빈 배열 `[]` 두지 말고 최소 1개 이상 채우기 (없으면 사용자에게 다시 묻기)
- 파일명에 한국어가 포함되어도 문제없음 (Hugo·GitHub Pages 모두 UTF-8 처리)
- 파일을 만든 후에는 git에 커밋하지 말 것. 사용자가 본문 작성 후 직접 커밋하거나 명시적으로 요청할 때만 커밋
