#!/usr/bin/env ruby

require 'net/http'
require 'json'
require 'uri'

class CloudflareDNSUpdater
  def initialize
    @zone_id = ENV['CLOUDFLARE_ZONE_ID'] || get_zone_id_from_config
    @api_token = ENV['CLOUDFLARE_API_TOKEN'] || get_api_token_from_config
    @domain = 'saju.click'
    @record_name = 'saju.click'  # 루트 도메인용, 서브도메인이면 'subdomain.saju.click'
    
    raise "CLOUDFLARE_ZONE_ID가 설정되지 않았습니다" unless @zone_id
    raise "CLOUDFLARE_API_TOKEN이 설정되지 않았습니다" unless @api_token
  end

  def get_zone_id_from_config
    # .env 파일이나 별도 설정 파일에서 읽기
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

  def get_current_eb_url
    # eb status 명령어로 현재 CNAME 가져오기
    eb_status = `eb status 2>/dev/null`
    
    if $?.success?
      cname_line = eb_status.lines.find { |line| line.include?('CNAME:') }
      if cname_line
        return cname_line.split('CNAME:').last.strip
      end
    end
    
    # eb status가 실패하면 직접 파싱 시도
    puts "eb status 실패, 기본값 사용"
    return "saju-simple.eba-p438umg4.ap-northeast-2.elasticbeanstalk.com"
  end

  def get_dns_record_id
    uri = URI("https://api.cloudflare.com/client/v4/zones/#{@zone_id}/dns_records")
    uri.query = URI.encode_www_form(name: @record_name, type: 'CNAME')
    
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    
    request = Net::HTTP::Get.new(uri)
    request['Authorization'] = "Bearer #{@api_token}"
    request['Content-Type'] = 'application/json'
    
    response = http.request(request)
    
    if response.code == '200'
      data = JSON.parse(response.body)
      if data['result'] && data['result'].any?
        return data['result'].first['id']
      end
    end
    
    nil
  end

  def get_current_dns_value
    uri = URI("https://api.cloudflare.com/client/v4/zones/#{@zone_id}/dns_records")
    uri.query = URI.encode_www_form(name: @record_name, type: 'CNAME')
    
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    
    request = Net::HTTP::Get.new(uri)
    request['Authorization'] = "Bearer #{@api_token}"
    request['Content-Type'] = 'application/json'
    
    response = http.request(request)
    
    if response.code == '200'
      data = JSON.parse(response.body)
      if data['result'] && data['result'].any?
        return data['result'].first['content']
      end
    end
    
    nil
  end

  def create_dns_record(target_url)
    uri = URI("https://api.cloudflare.com/client/v4/zones/#{@zone_id}/dns_records")
    
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    
    request = Net::HTTP::Post.new(uri)
    request['Authorization'] = "Bearer #{@api_token}"
    request['Content-Type'] = 'application/json'
    
    request.body = {
      type: 'CNAME',
      name: @record_name,
      content: target_url,
      ttl: 300
    }.to_json
    
    response = http.request(request)
    
    if response.code == '200'
      puts "DNS 레코드 생성 성공: #{@record_name} -> #{target_url}"
      return true
    else
      puts "DNS 레코드 생성 실패: #{response.body}"
      return false
    end
  end

  def update_dns_record(record_id, target_url)
    uri = URI("https://api.cloudflare.com/client/v4/zones/#{@zone_id}/dns_records/#{record_id}")
    
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    
    request = Net::HTTP::Put.new(uri)
    request['Authorization'] = "Bearer #{@api_token}"
    request['Content-Type'] = 'application/json'
    
    request.body = {
      type: 'CNAME',
      name: @record_name,
      content: target_url,
      ttl: 300
    }.to_json
    
    response = http.request(request)
    
    if response.code == '200'
      puts "DNS 업데이트 성공: #{@record_name} -> #{target_url}"
      return true
    else
      puts "DNS 업데이트 실패: #{response.body}"
      return false
    end
  end

  def update_dns
    current_eb_url = get_current_eb_url
    puts "현재 EB URL: #{current_eb_url}"
    
    current_dns_value = get_current_dns_value
    puts "현재 DNS 값: #{current_dns_value}"
    
    if current_dns_value == current_eb_url
      puts "DNS가 이미 최신 상태입니다."
      return true
    end
    
    record_id = get_dns_record_id
    
    if record_id
      puts "기존 DNS 레코드 업데이트 중..."
      update_dns_record(record_id, current_eb_url)
    else
      puts "DNS 레코드가 없어서 새로 생성 중..."
      create_dns_record(current_eb_url)
    end
  end
end

# 스크립트 실행
if __FILE__ == $0
  begin
    updater = CloudflareDNSUpdater.new
    updater.update_dns
  rescue => e
    puts "오류 발생: #{e.message}"
    exit 1
  end
end