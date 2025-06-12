#!/bin/bash

# 배포 후 DNS 자동 업데이트 스크립트

set -e  # 오류 발생시 스크립트 중단

echo "🚀 Elastic Beanstalk 배포 시작..."

# EB 배포
eb deploy

# 배포 성공 확인
if [ $? -eq 0 ]; then
    echo "✅ EB 배포 완료"
    echo "🌐 Cloudflare DNS 업데이트 중..."
    
    # DNS 업데이트
    ruby scripts/update-cloudflare-dns.rb
    
    if [ $? -eq 0 ]; then
        echo "✅ DNS 업데이트 완료"
        echo "🎉 배포 및 DNS 업데이트가 모두 완료되었습니다!"
        
        # 현재 상태 출력
        echo ""
        echo "=== 현재 상태 ==="
        eb status | grep -E "(CNAME|Status|Health)"
        echo ""
        echo "🌍 웹사이트: https://saju.click"
    else
        echo "❌ DNS 업데이트 실패"
        exit 1
    fi
else
    echo "❌ EB 배포 실패"
    exit 1
fi