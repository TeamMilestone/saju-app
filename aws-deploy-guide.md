# AWS Elastic Beanstalk 배포 가이드

## 사전 준비사항

1. AWS CLI 설치 및 구성
2. EB CLI 설치: `brew install awsebcli`
3. AWS 계정에 다음 권한 필요:
   - Elastic Beanstalk 전체 권한
   - Route53 레코드 생성 권한
   - ACM (Certificate Manager) 인증서 생성 권한

## 배포 단계

### 1. SSL 인증서 생성 (AWS Certificate Manager)

AWS 콘솔에서 ACM으로 이동하여 다음 도메인들을 포함하는 인증서 요청:
- `*.cvvcv.click`
- `*.codingvi.be`
- `cvvcv.click`
- `codingvi.be`

### 2. Elastic Beanstalk 초기화 및 배포

```bash
# 프로젝트 디렉토리로 이동
cd /Users/wonsup-mini/projects/saju-prompt/saju-app

# EB 초기화
eb init -p ruby-3.0 saju-app --region ap-northeast-2

# 환경 생성 (처음 배포시)
eb create saju-env --elb-type application

# 또는 기존 환경에 배포
eb deploy
```

### 3. HTTPS 설정

```bash
# EB 환경 설정 편집
eb config

# 다음 섹션을 찾아서 수정:
# aws:elbv2:listener:443:
#   SSLCertificateArns: 'arn:aws:acm:ap-northeast-2:YOUR_ACCOUNT_ID:certificate/CERTIFICATE_ID'
#   Protocol: HTTPS
```

### 4. Route53 도메인 설정

#### cvvcv.click 도메인 설정:
1. AWS 콘솔에서 Route53 접속
2. cvvcv.click 호스팅 영역 선택
3. 레코드 생성:
   - 레코드 이름: `saju`
   - 레코드 유형: `CNAME`
   - 값: EB 환경 URL (예: `saju-env.eba-xxxxx.ap-northeast-2.elasticbeanstalk.com`)
   - TTL: 300

#### codingvi.be 도메인 설정:
1. codingvi.be 호스팅 영역 선택
2. 동일한 방식으로 레코드 생성:
   - 레코드 이름: `saju`
   - 레코드 유형: `CNAME`
   - 값: 동일한 EB 환경 URL

### 5. CloudFormation을 이용한 자동 배포 (선택사항)

```bash
# S3 버킷 생성 (처음 한 번만)
aws s3 mb s3://saju-app-deployment-bucket-YOUR_UNIQUE_ID

# 애플리케이션 압축
zip -r saju-app.zip . -x "*.git*" "*.DS_Store" "*test*"

# S3에 업로드
aws s3 cp saju-app.zip s3://saju-app-deployment-bucket-YOUR_UNIQUE_ID/

# CloudFormation 스택 생성
aws cloudformation create-stack \
  --stack-name saju-app-stack \
  --template-body file://cloudformation-template.yaml \
  --parameters ParameterKey=SSLCertificateArn,ParameterValue=YOUR_CERTIFICATE_ARN \
  --capabilities CAPABILITY_IAM
```

### 6. 배포 확인

```bash
# EB 환경 상태 확인
eb status

# 애플리케이션 열기
eb open

# 로그 확인
eb logs
```

## 문제 해결

### SSL 인증서가 작동하지 않는 경우:
1. ACM에서 인증서가 "발급됨" 상태인지 확인
2. 인증서가 ap-northeast-2 리전에 있는지 확인
3. EB 환경의 로드 밸런서 리스너 설정 확인

### 도메인이 연결되지 않는 경우:
1. Route53 레코드가 올바르게 생성되었는지 확인
2. DNS 전파 시간 대기 (최대 48시간)
3. `nslookup saju.cvvcv.click` 명령으로 DNS 확인

### 배포가 실패하는 경우:
1. `eb logs` 명령으로 로그 확인
2. Ruby 버전 호환성 확인
3. Gemfile.lock이 커밋되어 있는지 확인

## 접속 URL

배포 완료 후 다음 URL로 접속 가능:
- https://saju.cvvcv.click
- https://saju.codingvi.be