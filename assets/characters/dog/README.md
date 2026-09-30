# 주인공 흰 강아지 v2

옷과 장비가 없는 흰 강아지 모델입니다. 몸통·얼굴을 연속 곡면으로 만들고 짧은 주둥이, 둥근 볼, 도톰한 발과 말린 꼬리로 다듬었습니다. 사실적인 털을 사용하지 않은 스타일화된 3D 모델입니다.

- `white_puppy_v2.glb`: 현재 사용하는 메시·재질·6개 애니메이션.
- `adventure_dog_v1.glb`: 장비가 있던 이전 버전 보관본. 현재 게임에서는 사용하지 않습니다.
- `motion-preview.png`: 실제 Godot 렌더링으로 촬영한 동작 시안.
- 생성 원본: `scripts/dog_visual.gd`.
- 게임 연결: `scripts/dog.gd`, 기존 코스와 마당 장면에 공통 적용.

## 동작

`idle`, `run`, `jump`, `double_jump`, `fall`, `land`.

모델은 +X가 정면, +Y가 위, 원점은 발밑입니다. 메시 파츠의 관절 변환으로 움직이며 연속 스킨 메시와 Skeleton3D를 사용하는 본 리깅은 아닙니다. GLB에는 이 관절 변환 동작을 30fps 키프레임으로 저장했습니다. 게임은 같은 원본 포즈 함수를 실시간 사용합니다.

점프 애니메이션은 가슴과 머리를 위로 들고 앞발을 접습니다. 모델 애니메이션에는 앞쪽이나 위쪽으로 움직이는 루트 이동이 없으며, 실제 높이는 CharacterBody3D 물리로 처리합니다. Space만 누르면 수직 점프, A/D와 함께 누르면 좌우로 조종하면서 상승합니다.

## 미리보기 / 재생성

```sh
/Applications/Godot.app/Contents/MacOS/Godot --path . res://dog_preview.tscn
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script tools/export_dog.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script tests/dog_asset.gd
```

`dog_preview.tscn`의 세 번째 강아지는 수직으로 도약 후 같은 위치로 착지합니다. 이 장면은 모델 감상용이며 조작 가능한 게임은 로비의 산책 시작 또는 조작 연습으로 실행합니다.
