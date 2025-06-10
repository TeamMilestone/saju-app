# 환경변수 및 환경파일 관리 가이드

이 문서는 사주 애플리케이션의 환경변수와 설정 파일을 안전하게 관리하는 방법을 설명합니다.

## 목차

1. [AWS Parameter Store 사용법](#aws-parameter-store-사용법)
2. [환경변수 종류](#환경변수-종류)
3. [로컬 개발 환경 설정](#로컬-개발-환경-설정)
4. [프로덕션 환경 설정](#프로덕션-환경-설정)
5. [보안 모범 사례](#보안-모범-사례)
6. [문제 해결](#문제-해결)

## AWS Parameter Store 사용법

### 1. Parameter Store란?

AWS Systems Manager Parameter Store는 설정 데이터와 시크릿을 안전하게 저장하고 관리하는 서비스입니다.

**장점:**
- 무료 (Standard 파라미터는 월 10,000개까지)
- 암호화 지원 (SecureString)
- IAM을 통한 세밀한 접근 제어
- 버전 관리

### 2. 파라미터 생성

```bash
# 일반 설정값 저장
aws ssm put-parameter \
  --name "/saju-app/rack-env" \
  --value "production" \
  --type "String" \
  --description "Rack environment setting" \
  --region ap-northeast-2

# 암호화된 시크릿 저장
aws ssm put-parameter \
  --name "/saju-app/openai-api-key" \
  --value "sk-proj-xxxxxxxxxxxx" \
  --type "SecureString" \
  --description "OpenAI API Key for chat completion" \
  --region ap-northeast-2

# SSL 인증서 ARN 저장
aws ssm put-parameter \
  --name "/saju-app/ssl-certificate-arn" \
  --value "arn:aws:acm:ap-northeast-2:123456789012:certificate/12345678-1234-1234-1234-123456789012" \
  --type "String" \
  --description "SSL certificate ARN for HTTPS" \
  --region ap-northeast-2
```

### 3. 파라미터 조회

```bash
# 단일 파라미터 조회
aws ssm get-parameter --name "/saju-app/rack-env" --region ap-northeast-2

# 암호화된 파라미터 조회 (복호화)
aws ssm get-parameter --name "/saju-app/openai-api-key" --with-decryption --region ap-northeast-2

# 특정 경로의 모든 파라미터 조회
aws ssm get-parameters-by-path --path "/saju-app" --recursive --region ap-northeast-2

# 암호화된 값도 포함하여 조회
aws ssm get-parameters-by-path --path "/saju-app" --recursive --with-decryption --region ap-northeast-2
```

### 4. 파라미터 업데이트

```bash
# 기존 파라미터 값 변경
aws ssm put-parameter \
  --name "/saju-app/openai-api-key" \
  --value "sk-proj-new-key-here" \
  --type "SecureString" \
  --overwrite \
  --region ap-northeast-2
```

### 5. 파라미터 삭제

```bash
# 파라미터 삭제
aws ssm delete-parameter --name "/saju-app/old-setting" --region ap-northeast-2

# 여러 파라미터 한번에 삭제
aws ssm delete-parameters --names "/saju-app/setting1" "/saju-app/setting2" --region ap-northeast-2
```

## 환경변수 종류

### 필수 환경변수

| 변수명 | Parameter Store 경로 | 타입 | 설명 |
|--------|---------------------|------|------|
| SSL_CERT_ARN | `/saju-app/ssl-certificate-arn` | String | HTTPS용 SSL 인증서 ARN |
| RACK_ENV | `/saju-app/rack-env` | String | Rack 환경 (production/development) |

### 선택적 환경변수

| 변수명 | Parameter Store 경로 | 타입 | 설명 |
|--------|---------------------|------|------|
| OPENAI_API_KEY | `/saju-app/openai-api-key` | SecureString | OpenAI API 키 |
| DATABASE_URL | `/saju-app/database-url` | SecureString | 데이터베이스 연결 문자열 |
| SESSION_SECRET | `/saju-app/session-secret` | SecureString | 세션 암호화 키 |

## 로컬 개발 환경 설정

### 1. .env 파일 사용

```bash
# .env 파일 생성 (이미 .gitignore에 포함됨)
touch .env
```

```env
# .env 파일 내용
RACK_ENV=development
OPENAI_API_KEY=sk-proj-your-development-key
DATABASE_URL=sqlite3:saju_development.db
```

### 2. dotenv gem 설치

```ruby
# Gemfile에 추가
gem 'dotenv', groups: [:development, :test]
```

```ruby
# app.rb 상단에 추가 (개발환경에서만)
require 'dotenv/load' if ENV['RACK_ENV'] == 'development'
```

### 3. Parameter Store에서 로컬로 동기화

```bash
# Parameter Store 값을 .env 파일로 내려받기
aws ssm get-parameters-by-path \
  --path "/saju-app" \
  --recursive \
  --with-decryption \
  --region ap-northeast-2 \
  --query "Parameters[*].[Name,Value]" \
  --output text | \
  sed 's|/saju-app/||g; s|\t|=|g' > .env.aws

# 생성된 파일 확인
cat .env.aws
```

## 프로덕션 환경 설정

### 1. Elastic Beanstalk에서 Parameter Store 참조

```bash
# EB 환경변수 설정
eb setenv \
  OPENAI_API_KEY='{{resolve:ssm-secure:/saju-app/openai-api-key}}' \
  RACK_ENV='{{resolve:ssm:/saju-app/rack-env}}' \
  DATABASE_URL='{{resolve:ssm-secure:/saju-app/database-url}}'
```

### 2. .ebextensions를 통한 자동 설정

```yaml
# .ebextensions/environment.config
option_settings:
  aws:elasticbeanstalk:application:environment:
    RACK_ENV: '{{resolve:ssm:/saju-app/rack-env}}'
    OPENAI_API_KEY: '{{resolve:ssm-secure:/saju-app/openai-api-key}}'
    DATABASE_URL: '{{resolve:ssm-secure:/saju-app/database-url}}'
```

### 3. CloudFormation에서 Parameter Store 참조

```yaml
# cloudformation-template.yaml
Parameters:
  SSLCertificateArn:
    Type: AWS::SSM::Parameter::Value<String>
    Default: /saju-app/ssl-certificate-arn
    Description: SSL certificate ARN from Parameter Store

Resources:
  SajuEnvironment:
    Type: AWS::ElasticBeanstalk::Environment
    Properties:
      OptionSettings:
        - Namespace: aws:elasticbeanstalk:application:environment
          OptionName: RACK_ENV
          Value: '{{resolve:ssm:/saju-app/rack-env}}'
        - Namespace: aws:elasticbeanstalk:application:environment
          OptionName: OPENAI_API_KEY
          Value: '{{resolve:ssm-secure:/saju-app/openai-api-key}}'
```

## 보안 모범 사례

### 1. 파라미터 타입 선택

```bash
# 민감하지 않은 설정: String
aws ssm put-parameter --name "/saju-app/app-name" --value "saju-app" --type "String"

# 민감한 정보: SecureString (KMS로 암호화)
aws ssm put-parameter --name "/saju-app/api-key" --value "secret" --type "SecureString"

# 큰 텍스트: StringList
aws ssm put-parameter --name "/saju-app/allowed-domains" --value "example.com,test.com" --type "StringList"
```

### 2. IAM 권한 설정

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ssm:GetParameter",
        "ssm:GetParameters",
        "ssm:GetParametersByPath"
      ],
      "Resource": "arn:aws:ssm:ap-northeast-2:*:parameter/saju-app/*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "kms:Decrypt"
      ],
      "Resource": "arn:aws:kms:ap-northeast-2:*:key/*",
      "Condition": {
        "StringEquals": {
          "kms:ViaService": "ssm.ap-northeast-2.amazonaws.com"
        }
      }
    }
  ]
}
```

### 3. 네이밍 컨벤션

```bash
# 좋은 예
/saju-app/database-url
/saju-app/api-keys/openai
/saju-app/ssl/certificate-arn
/saju-app/feature-flags/chat-enabled

# 나쁜 예
/database_url
/API_KEY
/ssl-cert
/chatEnabled
```

## 문제 해결

### 1. Parameter Store 관련 오류

```bash
# 파라미터가 존재하지 않는 경우
aws ssm describe-parameters --filters "Key=Name,Values=/saju-app/" --region ap-northeast-2

# 권한 오류 확인
aws sts get-caller-identity
aws iam get-user

# KMS 권한 확인 (SecureString 사용 시)
aws kms describe-key --key-id alias/aws/ssm --region ap-northeast-2
```

### 2. Elastic Beanstalk 환경변수 문제

```bash
# 현재 EB 환경변수 확인
eb printenv

# EB 설정 확인
eb config

# EB 로그에서 환경변수 로드 오류 확인
eb logs --all
```

### 3. CloudFormation 배포 오류

```bash
# CloudFormation 스택 이벤트 확인
aws cloudformation describe-stack-events --stack-name saju-app-stack --region ap-northeast-2

# 파라미터 값 검증
aws ssm get-parameter --name "/saju-app/ssl-certificate-arn" --region ap-northeast-2
```

### 4. 로컬 개발 환경 문제

```bash
# .env 파일 로드 확인
ruby -e "require 'dotenv/load'; puts ENV['OPENAI_API_KEY']"

# Parameter Store 연결 테스트
aws ssm get-parameter --name "/saju-app/rack-env" --region ap-northeast-2
```

## 유용한 스크립트

### 1. 모든 파라미터 백업

```bash
#!/bin/bash
# backup-parameters.sh

mkdir -p backup
aws ssm get-parameters-by-path \
  --path "/saju-app" \
  --recursive \
  --with-decryption \
  --region ap-northeast-2 \
  --output json > backup/parameters-$(date +%Y%m%d).json

echo "Parameters backed up to backup/parameters-$(date +%Y%m%d).json"
```

### 2. 파라미터 일괄 복원

```bash
#!/bin/bash
# restore-parameters.sh

if [ -z "$1" ]; then
  echo "Usage: $0 <backup-file>"
  exit 1
fi

jq -r '.Parameters[] | [.Name, .Value, .Type] | @tsv' "$1" | \
while IFS=$'\t' read -r name value type; do
  aws ssm put-parameter \
    --name "$name" \
    --value "$value" \
    --type "$type" \
    --overwrite \
    --region ap-northeast-2
  echo "Restored: $name"
done
```

### 3. 환경별 파라미터 동기화

```bash
#!/bin/bash
# sync-env.sh

SOURCE_ENV=${1:-development}
TARGET_ENV=${2:-staging}

aws ssm get-parameters-by-path \
  --path "/saju-app/$SOURCE_ENV" \
  --recursive \
  --with-decryption \
  --region ap-northeast-2 \
  --query "Parameters[*].[Name,Value,Type]" \
  --output text | \
while IFS=$'\t' read -r name value type; do
  target_name=$(echo "$name" | sed "s|/$SOURCE_ENV/|/$TARGET_ENV/|")
  aws ssm put-parameter \
    --name "$target_name" \
    --value "$value" \
    --type "$type" \
    --overwrite \
    --region ap-northeast-2
  echo "Synced: $name -> $target_name"
done
```

## 비용 최적화

### Parameter Store 요금 (2024년 기준)

| 타입 | 월 요금 | API 호출 요금 |
|------|---------|---------------|
| Standard | 무료 (10,000개까지) | 무료 |
| Advanced | $0.05/개 | $0.05/10,000회 |

### 권장사항

1. **Standard 파라미터 사용**: 대부분의 경우 충분
2. **적절한 캐싱**: 애플리케이션에서 파라미터 값 캐싱
3. **배치 조회**: `get-parameters-by-path` 사용하여 한번에 여러 값 조회
4. **불필요한 파라미터 정리**: 정기적으로 사용하지 않는 파라미터 삭제

```bash
# 사용하지 않는 파라미터 찾기
aws ssm describe-parameters \
  --filters "Key=Name,Values=/saju-app/" \
  --query "Parameters[?LastModifiedDate<'2024-01-01'].[Name,LastModifiedDate]" \
  --output table
```