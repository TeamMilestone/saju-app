# Cloudflare DNS 자동 업데이트 설정

## 1. 설정 파일 생성

`.cloudflare-config` 파일을 생성하고 클라우드플레어 정보를 입력하세요:

```bash
cp .cloudflare-config.example .cloudflare-config
```

`.cloudflare-config` 파일을 편집하여 실제 값 입력:

```json
{
  "zone_id": "클라우드플레어_존_ID",
  "api_token": "클라우드플레어_API_토큰"
}
```

## 2. 클라우드플레어 API 토큰 생성

1. [Cloudflare Dashboard](https://dash.cloudflare.com/) 로그인
2. **My Profile** → **API Tokens** → **Create Token**
3. **Custom token** 선택
4. 권한 설정:
   - **Zone:Zone:Read**
   - **Zone:DNS:Edit**
5. Zone Resources: **Include - Specific zone - saju.click**

## 3. 존 ID 확인

1. Cloudflare Dashboard에서 saju.click 도메인 선택
2. 오른쪽 사이드바에서 **Zone ID** 복사

## 4. 환경변수 설정 (선택사항)

설정 파일 대신 환경변수로도 설정 가능:

```bash
export CLOUDFLARE_ZONE_ID="your_zone_id"
export CLOUDFLARE_API_TOKEN="your_api_token"
```

## 5. 사용법

### 수동 DNS 업데이트
```bash
ruby scripts/update-cloudflare-dns.rb
```

### 배포 + DNS 업데이트 자동화
```bash
./scripts/deploy-and-update-dns.sh
```

## 6. 자동화 설정

### GitHub Actions (선택사항)
`.github/workflows/deploy.yml` 파일에 다음 추가:

```yaml
- name: Update Cloudflare DNS
  run: ruby scripts/update-cloudflare-dns.rb
  env:
    CLOUDFLARE_ZONE_ID: ${{ secrets.CLOUDFLARE_ZONE_ID }}
    CLOUDFLARE_API_TOKEN: ${{ secrets.CLOUDFLARE_API_TOKEN }}
```

## 보안 주의사항

- `.cloudflare-config` 파일은 절대 Git에 커밋하지 마세요
- API 토큰은 최소 권한으로 설정하세요
- 정기적으로 API 토큰을 갱신하세요