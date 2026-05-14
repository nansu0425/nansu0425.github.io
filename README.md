# nansu0425.github.io

Personal blog built with [Hugo](https://gohugo.io/) and [PaperMod](https://github.com/adityatelange/hugo-PaperMod) theme, deployed to GitHub Pages.

## Local Development

```bash
hugo server -D
```

Visit http://localhost:1313/

## New Post

```bash
hugo new posts/my-post.md
```

Or create a file manually in `content/posts/`.

## Deploy

Push to `main` branch — GitHub Actions will build and deploy automatically.

## Mobile (Claude Code on Web)

claude.ai/code 모바일 세션에서 포스트를 작성·배포할 수 있도록 설정되어 있습니다.

- `/new-post <title>` — frontmatter가 자동으로 채워진 draft 포스트를 `content/posts/`에 생성
- `draft: true` 상태로 main에 푸시해도 사이트에 노출되지 않음 (안전)
- 검토 후 `draft: false`로 변경하여 다시 푸시하면 GitHub Actions가 정식 배포

자세한 컨벤션은 [`CLAUDE.md`](./CLAUDE.md)를 참고하세요.
