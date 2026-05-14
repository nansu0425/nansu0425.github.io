# CLAUDE.md

이 저장소는 Hugo + PaperMod 테마 기반 개인 블로그 (`https://nansu0425.github.io`)입니다. 이 문서는 Claude Code가 매 세션에서 자동으로 읽어 블로그 작성·배포 컨벤션을 따르도록 하기 위한 가이드입니다.

## 사이트 개요

- **정적 사이트 생성기**: Hugo 0.147.0 extended (`.github/workflows/hugo.yml`에 버전 고정)
- **테마**: PaperMod (git submodule, `themes/PaperMod/`)
- **배포**: GitHub Actions가 `main` 브랜치 푸시 시 자동 빌드 후 GitHub Pages에 배포
- **수식 엔진**: KaTeX (CDN, `layouts/partials/extend_head.html`)
- **다이어그램**: TikZJax (CDN, `layouts/shortcodes/tikz.html`)

## 디렉토리 구조

```
content/
  posts/           # 블로그 포스트 (.md)
  about.md
  archives.md
  search.md
layouts/
  partials/extend_head.html   # math/tikz CDN 로드 (frontmatter 플래그로 조건부)
  shortcodes/tikz.html        # {{< tikz >}} 정의
themes/PaperMod/   # 서브모듈 - 절대 수정 금지
hugo.toml          # Hugo 설정 (KaTeX delimiters 등)
.github/workflows/hugo.yml   # 자동 배포 워크플로우
```

## 포스트 작성 규약

### 위치와 파일명

- 모든 포스트는 `content/posts/` 아래에 단일 `.md` 파일로 생성
- 파일명: 한국어 제목을 그대로 kebab-case로 변환 (공백 → 하이픈)
  - 예: `2D-점이-삼각형-내부에-있는지-판정하는-방법.md`
  - 예: `FPS-카메라를-위한-회전-행렬-곱-순서.md`

### Frontmatter 템플릿

```yaml
---
title: "포스트 제목"
date: YYYY-MM-DD
tags: ["tag1", "tag2"]
categories: ["Category"]
summary: "한 줄 요약 — 목록 페이지에 표시됨"
description: "검색 엔진과 SNS 공유에 쓰이는 더 긴 설명 (1~2문장)"
math: true       # 수식 사용 시 (KaTeX 로드)
tikz: true       # TikZ 다이어그램 사용 시 (TikZJax 로드)
draft: true      # 신규 포스트는 항상 true로 시작
---
```

- `math`, `tikz`는 사용하지 않으면 생략 또는 `false` (불필요한 CDN 로드 방지)
- `draft: true`인 포스트는 `hugo --gc --minify`(프로덕션 빌드)에서 제외되어 사이트에 노출되지 않음

## Draft 워크플로우 (배포 안전망)

모바일에서 시각 프리뷰 없이 안전하게 작성·배포하기 위한 핵심 워크플로우.

1. **작성**: `/new-post <제목>` 또는 수동으로 `draft: true`인 포스트 생성
2. **푸시**: `main`에 바로 커밋·푸시해도 안전 — Hugo가 빌드에서 제외하므로 사이트에 노출되지 않음
3. **검토**: Claude와 함께 마크다운/frontmatter를 다시 읽으며 점검
4. **공개**: `draft: false`로 바꾸고 다시 커밋·푸시 → GitHub Actions가 자동 배포

> ⚠️ 검토 없이 바로 공개하려면 처음부터 `draft: false`로 작성. 그러나 모바일 환경에서는 항상 draft로 시작하는 것을 권장.

## 수식·다이어그램·코드

### KaTeX 수식

- frontmatter에 `math: true` 필수
- 인라인: `$E = mc^2$` 또는 `\(E = mc^2\)`
- 블록: `$$ ... $$` 또는 `\[ ... \]`
- Goldmark passthrough가 `hugo.toml`에 설정되어 있어 마크다운 파서가 수식을 건드리지 않음

### TikZ 다이어그램

- frontmatter에 `tikz: true` 필수
- shortcode 사용:
  ```
  {{< tikz >}}
  \begin{tikzpicture}
    ...
  \end{tikzpicture}
  {{< /tikz >}}
  ```
- 흰 배경 박스로 자동 감싸짐 (`layouts/shortcodes/tikz.html`)

### 코드 블록

- ` ```언어 ` 형태로 사용, monokai 스타일과 line numbers 자동 적용 (`hugo.toml` `[markup.highlight]`)

## 본문 구조 컨벤션

기존 포스트 두 편(`FPS-카메라를-위한-회전-행렬-곱-순서.md`, `2D-점이-삼각형-내부에-있는지-판정하는-방법.md`)에서 관찰되는 패턴:

- `## 문제` 또는 `## 배경` 으로 시작 (왜 이 글을 쓰는지)
- 중간에 `## 핵심 명제`, `## 수식으로 증명`, `## 구체 예시` 등 단계별 전개
- 마지막에 `## 요약` 으로 마무리
- 한국어로 작성, 기술 용어는 영문 그대로 (예: row-vector, World Matrix)

## 배포 규칙

- **트리거**: `main` 브랜치 푸시 → `.github/workflows/hugo.yml` 실행
- **paths-ignore**: `.gitignore`, `README.md`, `LICENSE` 변경만으로는 배포되지 않음
- **빌드 명령**: `hugo --gc --minify --baseURL <pages-url>` (draft 미포함)
- **소요 시간**: 보통 1~2분

## 주의사항

- ❌ `themes/PaperMod/` 내부 파일을 절대 수정하지 말 것 (서브모듈, 커스터마이징은 `layouts/`에서 오버라이드)
- ❌ `public/` 디렉토리는 빌드 산출물 — 커밋하지 말 것 (`.gitignore`에 등록되어 있음)
- ❌ frontmatter의 `title`, `date` 누락 시 빌드 실패 가능
- ✅ 새 포스트는 항상 `draft: true`로 시작
- ✅ 커스텀 shortcode가 필요하면 `layouts/shortcodes/`에 추가 후 frontmatter 플래그로 조건부 로드 (`extend_head.html` 패턴 참고)

## 모바일 워크플로우 요약

```
/new-post 새 포스트 제목
  ↓
content/posts/새-포스트-제목.md 자동 생성 (draft: true)
  ↓
본문 작성 → git add → git commit → git push origin main
  ↓
GitHub Actions 빌드 (draft이므로 사이트엔 노출 X)
  ↓
Claude와 마크다운 리뷰
  ↓
draft: false로 변경 → 다시 push → 사이트 공개
```
