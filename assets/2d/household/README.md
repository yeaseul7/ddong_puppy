# 생활용품 장애물

사용자가 제공한 투명 PNG 원본 10종을 그대로 사용합니다.

- onggi: 항아리
- rattan_chair: 등나무 의자
- brick_well: 벽돌 구조물
- parasol_table: 파라솔 탁자
- stereo: 오디오
- cabinet: 장식장
- quilt: 꽃무늬 이불
- blue_chair: 파란 의자
- planters: 화분 받침
- sliding_door: 미닫이문

`scenes/2d/household/`의 각 장면은 Sprite2D와 CollisionPolygon2D가 포함된 StaticBody2D입니다. 장면 원점은 대표 착지면에 맞춰져 있습니다. 의자와 파라솔은 여러 충돌 다각형으로 나누고, 화분의 잎에는 충돌을 넣지 않았습니다. 충돌은 그림의 주요 형태를 단순화한 양방향 고정 지형이며 픽셀 단위 판정은 아닙니다.

`map_2d.tscn`에는 장애물 71개가 배치되어 있습니다. 편집기에서 Platforms 아래 물체를 이동하거나 자식 CollisionPolygon2D를 수정할 수 있습니다. 이미지 비율을 유지하고 낮은 천장의 이불은 작게 배치했습니다.

검증: tests/household_collision.gd (10종 착지면·투명도·다각형), tests/map_2d.gd (주 경로 69회 점프·양쪽 추락).

주의: tools/replace_household.gd는 교체 전 CollisionShape2D 기반 맵을 변환하는 일회성 도구입니다. 현재 맵에서 재실행하지 마세요.

## 추가 6종

- onggi_tall: 키 큰 항아리
- onggi_wide: 넓은 항아리
- onggi_knob: 손잡이 뚜껑 항아리
- brass_kettle: 양은 주전자 (손잡이·몸통·주둥이 충돌 분리)
- ceramic_pot: 꽃무늬 도자기 단지
- red_basket: 빨간 바구니 (작은 격자 구멍은 충돌 외곽에 포함)

총 16종입니다. 추가 6종은 기존 코스 18곳에 3개씩 섞었으며 전체 발판 수와 착지 목표 위치는 유지했습니다. tests/household_collision.gd는 전체 16종을 검사합니다. tools/add_household_variants.gd는 해당 18개 위치를 다시 생성하므로 수동 편집 이후에는 실행하지 마세요.
