# 백구 모델 v4 — 참고 이미지 기반 별도 모델링

사용자가 제공한 진돗개 정면·측면 이미지를 보며 로컬에서 별도로 모델링했습니다. 외부 이미지→3D AI 서비스의 자동 변환 결과나 구매한 원본이 아닙니다.

## 달라진 구조

- 몸통·목·머리·어깨·허벅지·다리·꼬리가 이어진 단일 표면.
- 16개 뼈대와 정점당 최대 4개 가중치를 가진 실제 스킨 메시.
- 검은 코와 콧구멍, 갈색 눈과 반사점, 작은 입 벌림·혀, 귀 안쪽, 발톱.
- 따뜻한 흰색 정점 색상과 미세한 방향성 노멀 텍스처.
- `idle`, `run`, `jump`, `double_jump`, `fall`, `land` 6개 동작.
- 점프 애니메이션은 가슴을 위로 들며 발을 접습니다. 실제 이동은 게임 물리가 담당합니다.

돌출 털 조각은 시험 렌더링에서 검은 점처럼 보여 최종 파일에서 제외했습니다. 사진의 풍성한 털과 사실적인 얼굴까지 재현한 최종 모델은 아니며, 현재는 매끄러운 표면을 가진 스타일화된 모델입니다.

## 파일

- `jindo_v4.glb`: 재질·스킨·동작이 들어 있는 게임용 모델.
- `jindo_sculpt.obj`: 다른 모델링 프로그램에서 다듬을 수 있는 몸체 메시. 뼈대와 재질은 GLB에 있습니다.
- `short_coat_normal.png`: 생성한 짧은 털 질감 노멀 맵(GLB에도 포함).
- `studio.png`: 실제 Godot 측면·사선·정면 렌더링.
- `build_stats.json`: 메시·뼈대 통계.

참고 원본은 `assets/reference/jindo-front-reference.png`, `jindo-side-reference.png`입니다.

## 재생성

원본 제작 스크립트: `tools/build_jindo.py`.
필요 패키지: numpy, scipy, scikit-image, Pillow. 현재 설치한 임시 런타임으로 실행:

```sh
PYTHONPATH=/private/tmp/ddong-modeling-deps /Users/iyeseul/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/bin/python3 tools/build_jindo.py
```

임시 패키지 경로가 삭제되면 별도 가상환경에 위 패키지를 설치해야 합니다. 메시를 부드럽게 합친 거리장에 marching cubes를 적용하고, 부위별 가중치와 역바인드 행렬을 포함한 glTF 2.0을 출력합니다. 사진으로부터 원본의 쿼드 토폴로지를 추출하는 방식은 아닙니다. 약 15만 삼각형으로, 모바일 배포 시 리토폴로지·LOD 최적화가 필요합니다.

## 실행 / 검증

```sh
/Applications/Godot.app/Contents/MacOS/Godot --path . res://jindo_studio.tscn
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script tests/smoke.gd --fixed-fps 60
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script tests/dog_asset.gd
```

모델 연결은 `scripts/jindo_visual.gd`, 플레이어는 `scripts/dog.gd`입니다. 스튜디오에서 Space로 대기/달리기를 전환하고 J로 도약 자세를 확인합니다. 이전 `dog_visual.gd`와 v1~v3 GLB는 보관본입니다.

기술 참고: https://github.com/KhronosGroup/glTF-Tutorials/blob/main/gltfTutorial/gltfTutorial_020_Skins.md
https://scikit-image.org/docs/stable/api/skimage.measure.html#skimage.measure.marching_cubes
