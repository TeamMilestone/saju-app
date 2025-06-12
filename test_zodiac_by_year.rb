require_relative 'zodiac_by_year'

# 1월 28일과 1월 29일로 테스트
def test_zodiac_2025
  puts "=== 2025년 띠 테스트 ==="
  
  # 1월 28일 (설날 전)
  zodiac_jan28 = ZodiacByYear.new(1, 28)
  result_jan28 = zodiac_jan28.zodiac_for_year(2025)
  puts "2025년 1월 28일 생일자의 띠: #{result_jan28}"
  puts "예상 결과: 용 (2024년 기준)"
  puts "테스트 통과: #{result_jan28 == '용' ? '✓' : '✗'}"
  
  puts ""
  
  # 1월 29일 (설날)
  zodiac_jan29 = ZodiacByYear.new(1, 29)
  result_jan29 = zodiac_jan29.zodiac_for_year(2025)
  puts "2025년 1월 29일 생일자의 띠: #{result_jan29}"
  puts "예상 결과: 뱀 (2025년 기준)"
  puts "테스트 통과: #{result_jan29 == '뱀' ? '✓' : '✗'}"
  
  puts "\n=== 전체 연도 띠 목록 (1월 28일 기준) ==="
  all_zodiacs = zodiac_jan28.zodiac_by_years
  
  # 샘플로 몇 개년도만 출력
  sample_years = [2020, 2021, 2022, 2023, 2024, 2025, 2026, 2027, 2028, 2029, 2030]
  sample_years.each do |year|
    puts "#{year}년: #{all_zodiacs[year]}"
  end
end

# 테스트 실행
test_zodiac_2025