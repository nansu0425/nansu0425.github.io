---
title: "FPS 카메라를 위한 회전 행렬 곱 순서"
date: 2026-04-13
tags: ["graphics", "math", "linear-algebra", "camera"]
categories: ["Graphics"]
summary: "World Matrix의 회전 부분을 Rz * Rx * Ry로 구성하는 이유를 row-vector 규약에서 수식으로 유도한다"
math: true
---

## 문제

게임 프로젝트의 수학 라이브러리에서 World Matrix의 회전 부분을 아래와 같이 구성했다.

```cpp
Float4x4 BuildWorld(const Transform& t)
{
    return BuildScale(t.scale)
         * BuildRotationZ(t.rotation.z)  // Roll
         * BuildRotationX(t.rotation.x)  // Pitch
         * BuildRotationY(t.rotation.y)  // Yaw
         * BuildTranslation(t.position);
}
```

회전만 떼어내면 $R_z(r) \cdot R_x(p) \cdot R_y(\theta)$ 순서다. 왜 하필 이 순서인가? 오일러 각은 어떤 순서로도 곱할 수 있는데, 이 배치가 FPS 카메라에 적합한 이유는 무엇인가?

## 배경 규약

본 프로젝트의 수학 라이브러리는 다음을 따른다.

- 좌표계: Left-handed
- 행렬 저장: row-major
- 벡터-행렬 곱: row-vector `v * M` (벡터가 행렬의 왼쪽에 옴)

row-vector 규약에서 $v \cdot A \cdot B \cdot C$는 왼쪽부터 순차 적용된다. 결합법칙에 의해

$$
v \cdot A \cdot B \cdot C = ((v \cdot A) \cdot B) \cdot C
$$

가 성립하고, **가장 마지막에 곱해지는 행렬이 최종 결과에 직접 작용**한다. 이 관찰이 이후 논의의 핵심이다.

## 오해: "회전 행렬은 그 자체로 월드 축 회전이다"

$R_y(\theta)$는 행렬 그 자체로 보면 월드 Y축을 중심으로 도는 회전 행렬이다. $R_x(\theta)$, $R_z(\theta)$도 마찬가지다. 이 성질은 다른 행렬과의 곱에 무관하다.

하지만 "각 행렬이 월드 축 회전"이라는 사실이 "해당 파라미터를 변화시켰을 때 결과 벡터가 월드 축 주위로 돈다"를 의미하지는 않는다. 행렬 곱은 비가환이기 때문이다. 파라미터 변화에 따른 궤적은 곱 순서에 따라 완전히 달라진다.

## 핵심 명제

> **$f(\theta) = v \cdot A \cdot R_y(\theta) \cdot B$ 형태에서 $\theta$를 변화시킬 때 관찰되는 회전축은 "월드 Y축을 $B$로 변환한 축"이다. $B = I$일 때만 관찰 축이 월드 Y축과 일치한다.**

즉, 곱 체인의 맨 오른쪽(마지막) 슬롯에 놓인 회전 행렬만이 "파라미터를 바꿀 때 월드 축 회전으로 관찰되는" 성질을 가진다.

## 수식으로 증명

카메라 forward 벡터를 $f_0 = (0, 0, 1)$이라 하자.

### Case 1: $M = R_z(r) \cdot R_x(p) \cdot R_y(\theta)$

$$
f(\theta) = f_0 \cdot R_z(r) \cdot R_x(p) \cdot R_y(\theta)
$$

결합법칙으로 묶으면

$$
f(\theta) = \underbrace{\left[ f_0 \cdot R_z(r) \cdot R_x(p) \right]}_{u\;(\theta\text{에 무관})} \cdot R_y(\theta) = u \cdot R_y(\theta)
$$

$u$는 $\theta$에 무관한 상수 벡터다. $u \cdot R_y(\theta)$는 정의상 **$u$를 월드 Y축 주위로 돌리는 궤적**이다. 즉, $\theta$가 변할 때 forward 벡터는 월드 Y축 기준의 원을 그린다.

### Case 2: $M = R_y(\theta) \cdot R_x(p) \cdot R_z(r)$

$$
f(\theta) = f_0 \cdot R_y(\theta) \cdot R_x(p) \cdot R_z(r)
$$

묶으면

$$
f(\theta) = \underbrace{\left[ f_0 \cdot R_y(\theta) \right]}_{g(\theta)} \cdot \underbrace{\left[ R_x(p) \cdot R_z(r) \right]}_{B\;(\theta\text{에 무관})}
$$

$g(\theta)$는 월드 Y축 기준 원이지만, 그 결과를 다시 상수 변환 $B$에 통과시킨다. 원을 선형 변환하면 또 다른 원(또는 타원)이 되는데, 그 축은 "월드 Y축을 $B$로 변환한 축"이 된다. 일반적으로 이 축은 월드 Y축과 일치하지 않는다.

### 일반 원리

임의의 $f(\theta) = A \cdot R_y(\theta) \cdot B$에서 $\theta$ 파라미터 변화 시 관찰되는 회전축은

$$
\text{(관찰 축)} = (\text{월드 Y축}) \cdot B
$$

$B = I$, 즉 $R_y$가 곱 체인의 맨 오른쪽에 있을 때만 관찰 축이 월드 Y축이 된다.

## 구체 예시: pitch $45°$, yaw $90°$

같은 파라미터라도 곱 순서에 따라 결과 행렬이 다름을 수치로 확인해 보자. $R_x(45°)$와 $R_y(90°)$를 row-vector 규약으로 두면

$$
R_x(45°) =
\begin{pmatrix}
1 & 0 & 0 \\
0 & \tfrac{\sqrt{2}}{2} & \tfrac{\sqrt{2}}{2} \\
0 & -\tfrac{\sqrt{2}}{2} & \tfrac{\sqrt{2}}{2}
\end{pmatrix}
, \quad
R_y(90°) =
\begin{pmatrix}
0 & 0 & -1 \\
0 & 1 & 0 \\
1 & 0 & 0
\end{pmatrix}
$$

### $R_x(45°) \cdot R_y(90°)$ (pitch 후 yaw — yaw가 맨 오른쪽)

$$
R_x(45°) \cdot R_y(90°) =
\begin{pmatrix}
0 & 0 & -1 \\
\tfrac{\sqrt{2}}{2} & \tfrac{\sqrt{2}}{2} & 0 \\
\tfrac{\sqrt{2}}{2} & -\tfrac{\sqrt{2}}{2} & 0
\end{pmatrix}
$$

$f_0 = (0, 0, 1)$을 적용하면 $f = (0,0,1) \cdot M$은 $M$의 3행과 같으므로

$$
f = \left( \tfrac{\sqrt{2}}{2},\; -\tfrac{\sqrt{2}}{2},\; 0 \right)
$$

forward의 Y 성분은 $-\tfrac{\sqrt{2}}{2}$로 pitch $45°$ 만큼 정확히 아래를 본다. yaw가 어떻게 변해도 pitch 성분이 그대로 보존된다.

### $R_y(90°) \cdot R_x(45°)$ (yaw 후 pitch — pitch가 맨 오른쪽)

$$
R_y(90°) \cdot R_x(45°) =
\begin{pmatrix}
0 & \tfrac{\sqrt{2}}{2} & -\tfrac{\sqrt{2}}{2} \\
0 & \tfrac{\sqrt{2}}{2} & \tfrac{\sqrt{2}}{2} \\
1 & 0 & 0
\end{pmatrix}
$$

두 결과는 완전히 다르다. 동일한 pitch, yaw 값이라도 곱 순서에 따라 forward 벡터가 가리키는 방향이 달라진다.

## FPS 카메라에 $R_z \cdot R_x \cdot R_y$를 적용하는 이유

핵심 명제에 비추어 각 슬롯의 의미를 해석한다.

### Yaw (Y) — 맨 오른쪽

FPS에서 마우스 좌우 조작은 지평선을 기울이지 않아야 한다. 이는 yaw 파라미터 변화 시 forward 벡터의 궤적이 **월드 Y축 기준 원**이어야 한다는 요구이고, 핵심 명제에 따라 $R_y$는 곱 체인의 맨 오른쪽에 와야만 한다. $R_z \cdot R_x \cdot R_y$에서 맨 오른쪽 슬롯을 차지하고 있으므로 이 요구가 충족된다.

### Pitch (X) — 중간

pitch는 관찰 축 기준으로 보면 "월드 X축을 $R_y(\theta)$로 변환한 축"이다. 엄밀히는 월드 X축이 아니지만, 일반적인 FPS 조작에서 roll = 0이고 yaw가 이미 적용된 상태에서 pitch를 움직이는 것은 "현재 바라보는 방향 기준으로 위/아래를 본다"는 자연스러운 행동에 대응한다. 수학적으로는 "yaw에 의해 회전된 X축" 기준 회전이지만, 이것이 바로 사용자가 기대하는 동작이다.

### Roll (Z) — 맨 왼쪽

roll은 캐릭터 고유의 기울기다. 피격 반응, 탑승물 기울기, 시네마틱 연출 등에서 설정되며, 이후 pitch/yaw가 그 기울어진 상태를 그대로 받아 적용된다. "roll $15°$로 기울어진 캐릭터가 위를 보고 옆을 본다"는 의미 구성이다.

## 요약

- 모든 회전 행렬은 그 자체로는 월드 축 회전이다.
- 그러나 파라미터 변화 시 관찰되는 회전축은 오른쪽에 곱해지는 행렬들에 의해 재해석된다. $f(\theta) = A \cdot R_y(\theta) \cdot B$의 관찰 축은 "월드 Y축을 $B$로 변환한 축"이다.
- 맨 오른쪽 슬롯의 회전만이 "월드 축 회전"으로 관찰된다.
- FPS 카메라가 yaw를 맨 오른쪽에 두는 것은 마우스 좌우 조작 시 지평선 유지를 보장하기 위한 수학적 귀결이며, $R_z \cdot R_x \cdot R_y$ 순서는 여기에서 도출된다.
