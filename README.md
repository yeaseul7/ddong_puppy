# 똥강아지

한국 시골 마당의 생활용품을 밟고 올라가는 Godot 4 기반 2D 플랫포머입니다.

## 실행

Godot 4.7 이상에서 프로젝트를 열고 F6 또는 F5를 누릅니다.

```sh
/Applications/Godot.app/Contents/MacOS/Godot --path .
```

시작 장면은 `lobby.tscn`이며 산책 시작 버튼으로 `map_2d.tscn`에 진입합니다.

## 조작

- 이동: `A`/`D` 또는 방향키
- 점프·2단 점프: `Space`
- 로비로 돌아가기: `Esc`
- 화면 모드 변경: 로비의 설정 메뉴

## 프로젝트 구조

- `lobby.tscn`, `scripts/lobby.gd`: 시작 화면과 설정 UI
- `map_2d.tscn`, `map_2d_2.tscn`, `scripts/2d/map.gd`: 한 장면에서 위로 이어지는 2개 코스 구간과 카메라
- `scripts/2d/dog.gd`: 캐릭터 이동·점프·애니메이션
- `scripts/2d/ground_visual.gd`: 지면 렌더링
- `scripts/display_settings.gd`: 창모드 설정 저장
- `assets/2d/household`: 발판으로 사용하는 생활용품 이미지
- `assets/2d/toys`, `scenes/2d/toys`: 투명 장난감·음식 이미지와 실루엣 충돌 장면
- `assets/2d/jindo_cartoon`: 강아지 스프라이트와 애니메이션
- `assets/environment/map01_sunset_valley.png`: 플레이 배경
- `assets/environment/map02_starfield.png`: 두 번째 맵 밤하늘 배경
- `assets/audio/before_the_kettle_cools.mp3`: 첫 번째 맵에서 반복 재생되는 배경음
- `assets/ui/lobby.png`: 로비 배경

## 검증

```sh
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script tests/map_2d.gd --fixed-fps 60
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script tests/map_routes.gd --fixed-fps 60
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script tests/display_modes.gd
```
