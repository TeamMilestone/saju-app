# Cloudflare 수동 설정 가이드

현재 saju.click에서 522 오류가 발생하는 이유는 Cloudflare가 HTTPS로 원본 서버에 연결하려고 하지만, Elastic Beanstalk는 HTTP만 지원하기 때문입니다.

## 해결 방법 1: Cloudflare 대시보드에서 직접 설정

### 1. SSL/TLS 설정 변경
1. [Cloudflare Dashboard](https://dash.cloudflare.com/) 로그인
2. **saju.click** 도메인 선택
3. **SSL/TLS** 탭 클릭
4. **Overview** 에서 **SSL/TLS encryption mode** 를 **"Flexible"** 로 변경
   - Flexible: 방문자 ↔ Cloudflare (HTTPS), Cloudflare ↔ 원본서버 (HTTP)

### 2. Always Use HTTPS 비활성화 (선택사항)
1. **SSL/TLS** → **Edge Certificates**
2. **Always Use HTTPS** 를 **"Off"** 로 설정

### 3. DNS 설정 확인
1. **DNS** 탭 클릭
2. **saju.click** (또는 **@**) 레코드가 다음과 같이 설정되어 있는지 확인:
   - **Type**: CNAME
   - **Name**: saju.click (또는 @)
   - **Content**: saju-simple.eba-p438umg4.ap-northeast-2.elasticbeanstalk.com
   - **Proxy status**: 🧡 Proxied (주황색 구름)

## 해결 방법 2: API 토큰 권한 추가

현재 API 토큰에 Zone Settings 편집 권한을 추가해야 합니다:

1. [Cloudflare Dashboard](https://dash.cloudflare.com/) → **My Profile** → **API Tokens**
2. 기존 토큰 **"Edit"** 클릭
3. **Permissions** 에 추가:
   - `Zone` : `Zone Settings` : `Edit`
4. **Continue to summary** → **Update Token**

그 다음 다시 스크립트 실행:
```bash
ruby scripts/fix-cloudflare-ssl.rb
```

## 테스트

설정 변경 후 2-3분 기다린 다음:

```bash
# HTTP 테스트
curl -I http://saju.click

# HTTPS 테스트  
curl -I https://saju.click

# 브라우저에서 확인
open https://saju.click
```

## 예상 결과

올바르게 설정되면:
- ✅ https://saju.click → 사주 분석 페이지 정상 표시
- ✅ HTTP 응답 코드 200
- ✅ SSL 인증서 오류 없음