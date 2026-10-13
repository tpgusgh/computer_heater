# Computer Heater 🔥

추운 날 Mac 위에 손 올려두고 쓰는 히터 앱.
CPU에 일부러 부하를 걸어 본체를 데웁니다.

## 기능

- **세기 조절** (5–100%) — 0.1초마다 지정한 비율만큼 계산하고 나머지는 쉼
- **코어 수 조절** — 1개부터 전체 코어까지
- **과열 자동 정지** — macOS 온도 상태가 `serious` 이상이면 멈추고, 식으면 다시 동작
- 메뉴바 🔥 아이콘 + 일반 창 + Dock 아이콘

## 설치

[Releases](https://github.com/tpgusgh/computer_heater/releases)에서 `Heater.dmg`를 받아 `Heater.app`을 응용 프로그램 폴더로 옮기세요.

정식 서명이 없어서 처음 실행할 때 경고가 뜹니다. **우클릭 → 열기**로 실행하세요.

## 직접 빌드

Xcode Command Line Tools(`swiftc`)가 필요합니다.

```sh
./build.sh
```

`build/Heater.app`, `build/Heater.dmg`가 생성됩니다.

## 사용 팁

- 처음엔 세기 50%, 코어 전부로 시작해 보세요.
- 배터리가 빨리 닳습니다. 충전기 연결 상태에서 쓰는 걸 추천합니다.
- 온도는 °C가 아니라 macOS가 알려주는 단계(정상/따뜻함/뜨거움/위험)로 표시됩니다.

## 요구 사항

macOS 13 이상 (Apple Silicon / Intel)
