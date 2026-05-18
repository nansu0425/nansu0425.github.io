---
title: "가상 함수와 vtable 동작 원리"
date: 2026-05-18
tags: ["cpp", "memory", "polymorphism", "interview"]
categories: ["C++"]
summary: "가상 함수의 동적 디스패치가 vptr과 vtable로 어떻게 구현되는지 객체 메모리 레이아웃 수준에서 분석한다"
description: "C++ 가상 함수의 동적 디스패치 메커니즘을 vptr/vtable과 객체 메모리 레이아웃으로 분석한다. 생성자에서의 가상 호출, virtual 소멸자, 호출 비용까지 신입 게임 프로그래머 면접 단골 주제."
tikz: true
---

## 문제

다음 코드의 출력은 무엇인가?

```cpp
struct Base
{
    virtual void Speak() { std::cout << "Base\n"; }
};

struct Derived : Base
{
    void Speak() override { std::cout << "Derived\n"; }
};

void Call(Base* p) { p->Speak(); }

int main()
{
    Derived d;
    Call(&d);   // ?
}
```

`Call`은 `Base*`만 보지만 출력은 `Derived`다. 컴파일 시점에는 `p`가 가리키는 실제 타입을 알 수 없는데, 어떻게 런타임에 올바른 함수가 선택되는가? 이것이 **동적 디스패치(dynamic dispatch)**이고, 그 구현이 vtable이다.

## 정적 바인딩 vs 동적 바인딩

`virtual`이 없는 함수의 호출은 컴파일 타임에 결정된다. `p->f()`에서 `p`의 **정적 타입**(선언된 타입)만 보고 호출 대상이 고정된다.

```cpp
struct Base { void f() { /* Base::f */ } };
struct Derived : Base { void f() { /* Derived::f */ } };

Base* p = new Derived;
p->f();   // Base::f — p의 정적 타입이 Base*이므로
```

`virtual`을 붙이면 호출 대상이 컴파일 타임에 고정되지 않고, `p`가 실제로 가리키는 객체의 **동적 타입**에 따라 런타임에 결정된다. 이 "런타임에 객체로부터 함수를 찾아오는" 동작을 위해 컴파일러는 추가 자료구조를 객체에 심는다.

## vtable과 vptr

가상 함수를 하나라도 가진 클래스마다 컴파일러는 **vtable(virtual table)**을 하나 생성한다. vtable은 그 클래스의 가상 함수 포인터들을 모아 둔 배열이며, 클래스당 하나만 존재한다(객체마다가 아니다).

그리고 그 클래스의 **모든 객체**는 첫 멤버로 숨겨진 포인터 **vptr**을 갖는다. vptr은 자신이 속한 클래스의 vtable을 가리킨다.

{{< tikz >}}
\begin{tikzpicture}[font=\small, node distance=0pt]
  % object
  \draw (0,0) rectangle (3,-0.7) node[midway] {vptr};
  \draw (0,-0.7) rectangle (3,-1.4) node[midway] {멤버 데이터...};
  \node at (1.5, 0.4) {Derived 객체};

  % vtable
  \draw (5,0) rectangle (8.5,-0.7) node[midway] {\&Derived::Speak};
  \draw (5,-0.7) rectangle (8.5,-1.4) node[midway] {\&Derived::Update};
  \node at (6.75, 0.4) {Derived vtable};

  % code
  \draw (10,0) rectangle (13,-0.7) node[midway] {Speak 코드};
  \draw (10,-0.7) rectangle (13,-1.4) node[midway] {Update 코드};

  % arrows
  \draw[->, thick] (3,-0.35) -- (5,-0.35);
  \draw[->, thick] (8.5,-0.35) -- (10,-0.35);
  \draw[->, thick] (8.5,-1.05) -- (10,-1.05);
\end{tikzpicture}
{{< /tikz >}}

핵심은 두 단계의 간접 참조다.

1. 객체에서 vptr을 읽는다 → 그 객체의 동적 타입에 해당하는 vtable을 얻는다.
2. vtable에서 호출하려는 함수의 슬롯을 읽는다 → 실제 함수 주소를 얻는다.

`Base`로 만든 객체의 vptr은 `Base` vtable을, `Derived`로 만든 객체의 vptr은 `Derived` vtable을 가리킨다. 같은 `p->Speak()` 코드라도 객체마다 vptr이 다르므로 다른 함수로 분기된다.

## 가상 호출의 컴파일 결과

`p->Speak()`가 가상 함수일 때 컴파일러가 생성하는 코드는 개념적으로 다음과 같다.

```cpp
// p->Speak() 와 동등
(*(p->vptr[ Speak의 슬롯 인덱스 ]))(p);
```

여기서 슬롯 인덱스는 **컴파일 타임 상수**다. `Speak`이 vtable의 0번이라는 사실은 클래스 정의에서 이미 정해진다. 런타임에 결정되는 것은 "어떤 vtable인가"뿐이고, "그 vtable의 몇 번 슬롯인가"는 고정이다.

이 구조 덕분에 비가상 함수 호출(주소 직접 호출) 대비 추가 비용은 **메모리 로드 두 번**(vptr 로드 + 슬롯 로드)과 **간접 점프 한 번**이다.

## vptr은 언제 설정되는가 — 생성자/소멸자의 함정

vptr은 객체가 만들어지는 순간 마법처럼 정해지는 게 아니라, **생성자가 단계적으로 설정**한다. 객체 생성은 기반 클래스 → 파생 클래스 순서로 진행되며, 각 단계에서 vptr이 해당 단계 클래스의 vtable로 갱신된다.

```cpp
struct Base
{
    Base() { Init(); }                  // 여기서 Init은?
    virtual void Init() { std::cout << "Base::Init\n"; }
};

struct Derived : Base
{
    void Init() override { std::cout << "Derived::Init\n"; }
};

int main()
{
    Derived d;   // 출력: Base::Init
}
```

`Base` 생성자가 실행되는 시점에는 아직 `Derived` 부분이 구성되지 않았다. 이때 vptr은 `Base` vtable을 가리키므로, 생성자 안에서의 가상 호출은 `Base::Init`으로 정적으로 해석된다. 소멸자도 대칭적으로 동작한다(파생 → 기반 순으로 소멸하며, 기반 소멸자에서는 vptr이 이미 `Base`로 되돌아가 있다).

> 면접 포인트: "생성자/소멸자 안에서 가상 함수를 호출하면 가상 디스패치가 일어나지 않는다"는 이 메커니즘의 직접적 귀결이다. 파생 클래스의 오버라이드가 호출되길 기대하면 안 된다.

## virtual 소멸자가 필요한 이유

```cpp
Base* p = new Derived;
delete p;   // Base::~Base만 호출 → Derived 자원 누수 (UB)
```

`delete p`는 `p`의 정적 타입(`Base*`)을 기준으로 소멸자를 호출한다. 소멸자가 가상이 아니면 정적 바인딩되어 `Base::~Base`만 실행되고 `Derived`의 소멸자는 건너뛴다. 다형적으로 사용할 의도로 `Base*`를 통해 `delete`할 클래스라면 소멸자를 `virtual`로 선언해야, 위 가상 호출 메커니즘을 통해 `Derived::~Derived`부터 호출된다.

## 비용과 메모리

- **공간**: 가상 함수를 가진 클래스의 객체마다 vptr 크기(보통 8바이트)가 추가된다. vtable 자체는 클래스당 하나이므로 객체 수와 무관하다.
- **시간**: 호출당 간접 참조 두 번. 단, 호출 대상이 컴파일 타임에 안 잡히므로 **인라인 최적화가 막힌다**는 점이 실제로는 더 크다. 게임의 매 프레임 수만 번 호출되는 핫 패스에서 가상 함수를 피하는 이유가 이것이다.
- **캐시**: vtable 접근은 객체 메모리와 다른 영역으로의 점프라 캐시 미스를 유발할 수 있다. 데이터 지향 설계에서 가상 함수 대신 타입별로 데이터를 분리하는 동기 중 하나다.

## 요약

- 가상 함수 호출은 동적 타입에 따라 런타임에 대상이 결정된다(동적 디스패치).
- 구현은 vptr(객체마다, 동적 타입의 vtable을 가리킴)과 vtable(클래스마다, 가상 함수 포인터 배열)의 2단계 간접 참조다.
- vtable 슬롯 인덱스는 컴파일 타임 상수이고, 런타임에 정해지는 것은 "어떤 vtable인가"뿐이다.
- 생성자/소멸자에서는 vptr이 아직/이미 해당 단계 클래스를 가리키므로 가상 디스패치가 일어나지 않는다.
- `Base*`로 다형적 `delete`를 한다면 소멸자는 반드시 `virtual`이어야 한다.
- 비용은 간접 참조 두 번보다 인라인 차단과 캐시 미스가 실질적으로 더 크다.
