# saju.click 도메인 설정 가이드

## 현재 상황
- 기존 도메인: saju.cvvcv.click (AWS Route53에서 관리)
- 새 도메인: saju.click (Cloudflare에서 관리)
- Elastic Beanstalk 환경: saju-simple.eba-p438umg4.ap-northeast-2.elasticbeanstalk.com

## 설정 단계

### 방법 1: Cloudflare에서 직접 CNAME 설정 (권장)

1. **Cloudflare 대시보드 접속**
   - https://dash.cloudflare.com 로그인
   - saju.click 도메인 선택

2. **DNS 레코드 추가**
   - DNS 관리 페이지로 이동
   - "Add record" 클릭
   - 다음 설정으로 레코드 생성:
     - Type: `CNAME`
     - Name: `@` (루트 도메인용)
     - Target: `saju-simple.eba-p438umg4.ap-northeast-2.elasticbeanstalk.com`
     - Proxy status: **Proxied** (주황색 구름 아이콘)
     - TTL: Auto

3. **SSL/TLS 설정**
   - SSL/TLS → Overview로 이동
   - Encryption mode를 **Full** 또는 **Full (strict)**로 설정
   - Edge Certificates가 활성화되어 있는지 확인

4. **Page Rules 설정 (선택사항)**
   - Page Rules로 이동
   - HTTP를 HTTPS로 강제 리다이렉트:
     - URL: `http://saju.click/*`
     - Setting: Always Use HTTPS

### 방법 2: AWS에서 도메인 관리 (대안)

Route53에서 saju.click 도메인을 관리하려면:

1. **도메인 네임서버 변경**
   - Cloudflare에서 도메인의 네임서버를 AWS Route53 네임서버로 변경
   - Route53에서 호스팅 영역 생성 후 네임서버 확인

2. **Route53 레코드 생성**
   ```bash
   # route53-saju-click.json 파일 생성
   {
       "Changes": [{
           "Action": "UPSERT",
           "ResourceRecordSet": {
               "Name": "saju.click",
               "Type": "A",
               "AliasTarget": {
                   "HostedZoneId": "Z3JE5OI70TWKCP",
                   "DNSName": "saju-simple.eba-p438umg4.ap-northeast-2.elasticbeanstalk.com",
                   "EvaluateTargetHealth": false
               }
           }
       }]
   }
   ```

### SSL 인증서 설정

현재 AWS ACM 인증서가 `*.cvvcv.click`과 `*.codingvi.be`만 포함하므로:

1. **새 ACM 인증서 요청** (AWS 콘솔)
   - Certificate Manager → Request certificate
   - 도메인 추가:
     - `saju.click`
     - `*.saju.click` (서브도메인용)
   - DNS 검증 선택

2. **Cloudflare에서 검증 레코드 추가**
   - ACM에서 제공하는 CNAME 검증 레코드를 Cloudflare DNS에 추가
   - Proxy status는 **DNS only** (회색 구름)로 설정

3. **EB 환경에 새 인증서 적용**
   ```bash
   eb config
   ```
   HTTPS 리스너의 SSLCertificateArns를 새 인증서 ARN으로 업데이트

## 권장사항

**Cloudflare 방법 1을 권장**하는 이유:
- Cloudflare의 CDN과 보안 기능 활용 가능
- DDoS 방어 및 성능 최적화
- 무료 SSL 인증서 자동 관리
- 설정이 간단하고 빠름

## 확인 방법

```bash
# DNS 전파 확인
nslookup saju.click
dig saju.click

# HTTPS 연결 테스트
curl -I https://saju.click
```

## 주의사항

- DNS 전파에는 최대 48시간이 걸릴 수 있음
- Cloudflare Proxy를 사용하면 실제 서버 IP가 숨겨짐
- AWS 로드밸런서의 보안 그룹이 Cloudflare IP 범위를 허용하는지 확인