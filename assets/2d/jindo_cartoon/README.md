# 카툰 진돗개 스프라이트

내장 image_gen으로 생성. 흰 털, 분홍 귀 안쪽, 말린 꼬리, 짙은 윤곽선의 오른쪽 측면 진돗개.

생성 프롬프트: transparent 1536×1024, 4×3 sprite sheet; cute cartoon white Korean Jindo puppy, upright triangular ears, curled tail, cream cel shading, clean dark outline; first row four idle poses, second row four run poses, third row jump/double jump/fall/land; no text, accessories or scenery.
후속 편집 프롬프트: remove background to genuine alpha, preserve all poses and placement.

- sheet.png: 실제 알파 투명도를 포함한 12포즈 시트.
- animations.tres: idle 4프레임, run 4프레임, jump/double_jump/fall/land 각 1포즈.
- preview.tres: 편집기 미리보기.
- tools/build_cartoon_frames.gd: 영역별 알파 경계로 AtlasTexture를 정렬. 공통 384px 캔버스, 발 기준선 340px.
- 게임 적용 크기 0.3, 발 기준 오프셋 -44.4px. 기존 이동 속도·점프·충돌은 유지.

실제 플레이 화면에서 투명 배경과 착지 위치를 확인했고 69개 구간 이동 테스트가 통과했습니다.
