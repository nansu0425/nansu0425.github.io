---
title: Jekyll 블로그 Github Actions 빌드 오류 (Setup Ruby 문제)
date: 2023-12-29 00:13 +0900
categories: [CI/CD, Github Actions]
tags: [jekyll, ci/cd, github actions, ruby, chirpy]     # TAG names should always be lowercase
---

## 환경
- **local OS**: Ubuntu 22.04.3 LTS
- **Github Pages**: <a href='https://github.com/cotes2020/jekyll-theme-chirpy' target='_blank'>Chirpy</a> 테마
- **CI/CD**: Github Actions

## 1. 문제

### 1.1. 발견
블로그를 로컬에서 수정한 후 push를 했다. 정상적인 경우라면 push 이후 Github Actions가 CI/CD를 수행하는데 별로 오래 걸리지 않는다. 하지만 생각보다 기다림의 시간이 길어졌고 확인해 보니 빌드 과정에서 문제가 발생했음을 확인했다.<br>
![img-01](/assets/img/23/12/28/img-01.png)<br>

### 1.2. 파악
build 과정의 log를 확인해 보기로 했다. Actions 탭에서 살펴보니 Setup Ruby 부분에서 실패했다는 것을 알 수 있었다.<br>
![img-02](/assets/img/23/12/28/img-02.png)<br>
아래는 Setup Ruby 과정에서 발생한 에러 메시지이다.<br>
![img-03](/assets/img/23/12/28/img-03.png)
> Error: The process '/opt/hostedtoolcache/Ruby/3.3.0/x64/bin/bundle' failed with exit code 5<br>

## 2. 해결

### 2.1. 원인 조사
에러 메시지를 구글에 검색해보니 비슷한 문제를 겪고 있는 사람의 <a href='https://talk.jekyllrb.com/t/build-error-at-setup-ruby-stage-of-build-and-deploy-on-actions/8782' target='_blank'>질문글</a>을 발견했다. 글을 읽어본 후 `.github/workflows/pages-deploy.yml` 파일 Setup Ruby 부분의 ruby 버전이 원인인 것 같았다.

### 2.2. 해결 시도
질문글의 답변들을 보면 ruby 버전을 3.2로 변경했더니 해결됐다고 했다. 그래서 내 블로그의 workflow 파일을 아래와 같이 수정한 후 commit했다.<br>
![img-04](/assets/img/23/12/28/img-04.png)
<center><a href='https://github.com/nansu0425/nansu0425.github.io/commit/57493f0e781b8cac826a8a3949194d8da8390388?diff=unified&w=0' target='_blank'>Commit 링크</a></center>

### 2.3. 결과
ruby 버전 수정 후 build와 deploy 모두 성공했다. 역시 구글은 신이다.<br>
![img-05](/assets/img/23/12/28/img-05.png)