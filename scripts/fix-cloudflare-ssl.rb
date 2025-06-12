#!/usr/bin/env ruby

require 'net/http'
require 'json'
require 'uri'

class CloudflareSSLFixer
  def initialize
    @zone_id = ENV['CLOUDFLARE_ZONE_ID'] || get_zone_id_from_config
    @api_token = ENV['CLOUDFLARE_API_TOKEN'] || get_api_token_from_config
    @domain = 'saju.click'
    
    raise "CLOUDFLARE_ZONE_ID가 설정되지 않았습니다" unless @zone_id
    raise "CLOUDFLARE_API_TOKEN이 설정되지 않았습니다" unless @api_token
  end

  def get_zone_id_from_config
    config_file = File.join(__dir__, '..', '.cloudflare-config')
    if File.exist?(config_file)
      config = JSON.parse(File.read(config_file))
      return config['zone_id']
    end
    nil
  end

  def get_api_token_from_config
    config_file = File.join(__dir__, '..', '.cloudflare-config')
    if File.exist?(config_file)
      config = JSON.parse(File.read(config_file))
      return config['api_token']
    end
    nil
  end

  def update_ssl_setting
    # SSL 모드를 Flexible로 변경 (Cloudflare에서 HTTPS, 원본 서버는 HTTP)
    uri = URI("https://api.cloudflare.com/client/v4/zones/#{@zone_id}/settings/ssl")
    
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    
    request = Net::HTTP::Patch.new(uri)
    request['Authorization'] = "Bearer #{@api_token}"
    request['Content-Type'] = 'application/json'
    
    request.body = {
      value: 'flexible'
    }.to_json
    
    response = http.request(request)
    
    if response.code == '200'
      data = JSON.parse(response.body)
      puts "SSL 설정 업데이트 성공: #{data['result']['value']}"
      return true
    else
      puts "SSL 설정 업데이트 실패: #{response.body}"
      return false
    end
  end

  def update_always_use_https
    # Always Use HTTPS 비활성화 (원본 서버가 HTTP만 지원하므로)
    uri = URI("https://api.cloudflare.com/client/v4/zones/#{@zone_id}/settings/always_use_https")
    
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    
    request = Net::HTTP::Patch.new(uri)
    request['Authorization'] = "Bearer #{@api_token}"
    request['Content-Type'] = 'application/json'
    
    request.body = {
      value: 'off'
    }.to_json
    
    response = http.request(request)
    
    if response.code == '200'
      data = JSON.parse(response.body)
      puts "Always Use HTTPS 설정: #{data['result']['value']}"
      return true
    else
      puts "Always Use HTTPS 설정 실패: #{response.body}"
      return false
    end
  end

  def check_current_settings
    # 현재 SSL 설정 확인
    uri = URI("https://api.cloudflare.com/client/v4/zones/#{@zone_id}/settings/ssl")
    
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    
    request = Net::HTTP::Get.new(uri)
    request['Authorization'] = "Bearer #{@api_token}"
    request['Content-Type'] = 'application/json'
    
    response = http.request(request)
    
    if response.code == '200'
      data = JSON.parse(response.body)
      puts "현재 SSL 모드: #{data['result']['value']}"
    end

    # Always Use HTTPS 설정 확인
    uri = URI("https://api.cloudflare.com/client/v4/zones/#{@zone_id}/settings/always_use_https")
    request = Net::HTTP::Get.new(uri)
    request['Authorization'] = "Bearer #{@api_token}"
    request['Content-Type'] = 'application/json'
    
    response = http.request(request)
    
    if response.code == '200'
      data = JSON.parse(response.body)
      puts "현재 Always Use HTTPS: #{data['result']['value']}"
    end
  end

  def fix_settings
    puts "=== Cloudflare SSL 설정 수정 ==="
    puts "현재 설정 확인 중..."
    check_current_settings
    
    puts "\nSSL 모드를 Flexible로 변경 중..."
    update_ssl_setting
    
    puts "\nAlways Use HTTPS 비활성화 중..."
    update_always_use_https
    
    puts "\n변경 후 설정 확인..."
    check_current_settings
    
    puts "\n🎉 Cloudflare 설정 수정 완료!"
    puts "몇 분 후 https://saju.click 에서 테스트해보세요."
  end
end

# 스크립트 실행
if __FILE__ == $0
  begin
    fixer = CloudflareSSLFixer.new
    fixer.fix_settings
  rescue => e
    puts "오류 발생: #{e.message}"
    exit 1
  end
end