# 사주 분석 애플리케이션

AWS Elastic Beanstalk에 배포하는 Sinatra 기반 사주 분석 웹 애플리케이션입니다.

## 기능

- 이름, 성별, 생년월일시 입력
- 사주원국, 십신, 12운성, 용신 계산
- SQLite3 데이터베이스에 정보 저장
- ChatGPT 프롬프트 생성 및 복사
- 결과 공유 기능

## AWS Elastic Beanstalk 배포 방법

### 사전 준비 (사무실에서 한 번만)

1. **AWS CLI 설치 및 구성:**
```bash
# AWS CLI 설치
pip install awscli awsebcli

# AWS 자격 증명 구성
aws configure
```

2. **기존 SSL 인증서 ARN 찾기:**
```bash
# 방법 1: AWS CLI로 모든 인증서 조회
aws acm list-certificates --region ap-northeast-2

# 방법 2: 특정 도메인으로 필터링
aws acm list-certificates --region ap-northeast-2 \
  --query "CertificateSummaryList[?contains(DomainName,'cvvcv.click')]"

# 방법 3: 기존 백업에서 확인
grep -r "arn:aws:acm" .git_backup/
```

3. **SSL 인증서 ARN을 Parameter Store에 저장:**
```bash
# 위에서 찾은 인증서 ARN을 Parameter Store에 저장
aws ssm put-parameter \
  --name "/saju-app/ssl-certificate-arn" \
  --value "arn:aws:acm:ap-northeast-2:258844523519:certificate/9b1d790a-44d6-4309-804b-074b662fee29" \
  --type "String" \
  --region ap-northeast-2

# 저장된 값 확인
aws ssm get-parameter --name "/saju-app/ssl-certificate-arn" --region ap-northeast-2
```

4. **기타 환경변수들을 Parameter Store에 저장 (필요한 경우):**
```bash
# OpenAI API Key (SecureString으로 암호화 저장)
aws ssm put-parameter \
  --name "/saju-app/openai-api-key" \
  --value "your-openai-api-key" \
  --type "SecureString" \
  --region ap-northeast-2

# 기타 설정값들
aws ssm put-parameter \
  --name "/saju-app/rack-env" \
  --value "production" \
  --type "String" \
  --region ap-northeast-2
```

### 배포 단계

1. **EB 초기화:**
```bash
cd saju-app
eb init -p ruby-3.0 saju-app --region ap-northeast-2
```

2. **EB 환경 생성:**
```bash
eb create saju-env
```

3. **배포:**
```bash
eb deploy
```

4. **애플리케이션 확인:**
```bash
eb open
```

### CloudFormation으로 전체 인프라 배포 (선택사항)

```bash
# CloudFormation 스택 생성
aws cloudformation create-stack \
  --stack-name saju-app-stack \
  --template-body file://cloudformation-template.yaml \
  --region ap-northeast-2
```

### 환경변수 관리

애플리케이션에서 Parameter Store 값을 사용하려면 EB 환경설정에서 다음과 같이 설정:

```bash
# EB 환경변수 설정 (Parameter Store 참조)
eb setenv \
  OPENAI_API_KEY='{{resolve:ssm-secure:/saju-app/openai-api-key}}' \
  RACK_ENV='{{resolve:ssm:/saju-app/rack-env}}'
```

### 중요 사항

- **무료 서비스**: Parameter Store Standard는 월 10,000개까지 무료
- **보안**: 민감한 정보는 `SecureString` 타입 사용
- **지역 설정**: 모든 리소스가 `ap-northeast-2` 리전에 생성됨
- **SSL 인증서**: 현재 `*.cvvcv.click` 와일드카드 인증서 사용
- **환경설정**: 자세한 환경변수 관리 방법은 [ENVIRONMENT.md](ENVIRONMENT.md) 참조

### 문제 해결

```bash
# EB 로그 확인
eb logs

# Parameter Store 값 확인
aws ssm get-parameter --name "/saju-app/ssl-certificate-arn"

# EB 환경 상태 확인
eb status
```

## 로컬 실행

1. 의존성 설치:
```bash
bundle install
```

2. 애플리케이션 실행:
```bash
ruby app.rb
```

3. 브라우저에서 http://localhost:4567 접속