require_relative 'app'

# 테스트 데이터: 1983년 5월 8일 오전 10시
year = 1983
month = 5
day = 8
hour = 10
minute = 0

puts "테스트: #{year}년 #{month}월 #{day}일 #{hour}시 출생"
puts "="*50

# 헬퍼 메서드를 포함하기 위해 Sinatra 앱 컨텍스트에서 실행
include Sinatra::Application.helpers

# 사주 계산
year_pillar = calculate_year_pillar(year, month, day)
month_pillar = calculate_month_pillar(year, month, day)
day_pillar = calculate_day_pillar(year, month, day)
hour_pillar = calculate_hour_pillar(year, month, day, hour, minute)

puts "년주: #{year_pillar}"
puts "월주: #{month_pillar}"
puts "일주: #{day_pillar}"
puts "시주: #{hour_pillar}"
puts "="*50

# 예상 결과와 비교
expected = {
  year: "계해",
  month: "정사",
  day: "병신",
  hour: "계사"
}

results = {
  year: year_pillar,
  month: month_pillar,
  day: day_pillar,
  hour: hour_pillar
}

puts "\n검증 결과:"
results.each do |key, value|
  if value == expected[key]
    puts "✓ #{key}주: #{value} (정확)"
  else
    puts "✗ #{key}주: #{value} (예상: #{expected[key]})"
  end
end

# 추가 정보 출력
puts "\n추가 정보:"
birth_date = Time.new(year, month, day)
puts "입춘 날짜: #{find_ipchun_date(year)}"
puts "절기 월: #{get_solar_month(birth_date)}"

# 일간 추출
day_stem = day_pillar[0]
puts "\n일간: #{day_stem}"
puts "용신: #{calculate_yongshin(day_stem)}"