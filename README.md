# 사주 분석 애플리케이션

AWS Elastic Beanstalk에 배포하는 Sinatra 기반 사주 분석 웹 애플리케이션입니다.

## 기능

- 이름, 성별, 생년월일시 입력
- 사주원국, 십신, 12운성, 용신 계산
- SQLite3 데이터베이스에 정보 저장
- ChatGPT 프롬프트 생성 및 복사
- 결과 공유 기능

## AWS Elastic Beanstalk 배포 방법

1. AWS CLI와 EB CLI 설치:
```bash
pip install awsebcli
```

2. EB 초기화:
```bash
cd saju-app
eb init -p ruby-3.0 saju-app --region ap-northeast-2
```

3. EB 환경 생성:
```bash
eb create saju-env
```

4. 배포:
```bash
eb deploy
```

5. 애플리케이션 열기:
```bash
eb open
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