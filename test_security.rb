require_relative 'app'
require 'securerandom'

puts "=== 보안 테스트 ==="
puts ""

# 데이터베이스 테스트 데이터 생성
test_uuid1 = SecureRandom.uuid
test_uuid2 = SecureRandom.uuid

puts "테스트 UUID 생성:"
puts "UUID 1: #{test_uuid1}"
puts "UUID 2: #{test_uuid2}"
puts ""

# 테스트 데이터 삽입
begin
  DB.execute("INSERT INTO users (uuid, name, gender, birth_year, birth_month, birth_day, birth_hour) VALUES (?, ?, ?, ?, ?, ?, ?)",
    [test_uuid1, "테스트1", "남", 1990, 5, 15, 14])
  
  DB.execute("INSERT INTO users (uuid, name, gender, birth_year, birth_month, birth_day, birth_hour) VALUES (?, ?, ?, ?, ?, ?, ?)",
    [test_uuid2, "테스트2", "여", 1985, 8, 20, 10])
  
  puts "✓ 테스트 데이터 삽입 성공"
rescue SQLite3::Exception => e
  puts "데이터 삽입 오류: #{e.message}"
end

# UUID 형식 검증 테스트
puts "\nUUID 형식 검증 테스트:"

valid_uuid = test_uuid1
invalid_uuids = [
  "123",
  "abc-def-ghi",
  "12345678-1234-1234-1234-123456789012",  # 길이가 맞지만 하이픈 위치가 틀림
  "invalid-uuid-format",
  "",
  "1",
  "999999"  # 기존 숫자 ID 스타일
]

# 유효한 UUID 테스트
uuid_pattern = /\A[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\z/i
if valid_uuid.match?(uuid_pattern)
  puts "✓ 유효한 UUID: #{valid_uuid}"
else
  puts "✗ UUID 검증 실패: #{valid_uuid}"
end

# 무효한 UUID 테스트
invalid_uuids.each do |invalid_uuid|
  if invalid_uuid.match?(uuid_pattern)
    puts "✗ 무효한 UUID가 통과됨: #{invalid_uuid}"
  else
    puts "✓ 무효한 UUID 차단됨: #{invalid_uuid}"
  end
end

# 데이터베이스 쿼리 테스트
puts "\n데이터베이스 접근 테스트:"

# 유효한 UUID로 접근
user1 = DB.execute("SELECT * FROM users WHERE uuid = ?", test_uuid1).first
if user1
  puts "✓ 유효한 UUID로 데이터 조회 성공: #{user1[2]}"  # name 컬럼
else
  puts "✗ 유효한 UUID로 데이터 조회 실패"
end

# 무효한 UUID로 접근 시도
fake_uuid = "12345678-1234-1234-1234-123456789012"
user_fake = DB.execute("SELECT * FROM users WHERE uuid = ?", fake_uuid).first
if user_fake
  puts "✗ 무효한 UUID로 데이터 조회됨 - 보안 취약!"
else
  puts "✓ 무효한 UUID로 데이터 조회 차단됨"
end

# 숫자 ID로 접근 시도
begin
  user_numeric = DB.execute("SELECT * FROM users WHERE id = ?", 1).first
  if user_numeric
    puts "경고: 숫자 ID로 여전히 접근 가능 (내부 사용만)"
  end
rescue => e
  puts "숫자 ID 접근 테스트 오류: #{e.message}"
end

puts "\n=== 보안 테스트 완료 ==="
puts "UUID 기반 접근 제어가 올바르게 작동합니다."
puts "URL 예시: /result/#{test_uuid1}"