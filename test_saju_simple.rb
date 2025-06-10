require 'time'

# 천간, 지지 상수
CHEONGAN = ["갑", "을", "병", "정", "무", "기", "경", "신", "임", "계"]
JIJI = ["자", "축", "인", "묘", "진", "사", "오", "미", "신", "유", "술", "해"]

# 60갑자 배열
SEXAGENARY_CYCLE = [
  "갑자", "을축", "병인", "정묘", "무진", "기사", "경오", "신미", "임신", "계유",
  "갑술", "을해", "병자", "정축", "무인", "기묘", "경진", "신사", "임오", "계미",
  "갑신", "을유", "병술", "정해", "무자", "기축", "경인", "신묘", "임진", "계사",
  "갑오", "을미", "병신", "정유", "무술", "기해", "경자", "신축", "임인", "계묘",
  "갑진", "을사", "병오", "정미", "무신", "기유", "경술", "신해", "임자", "계축",
  "갑인", "을묘", "병진", "정사", "무오", "기미", "경신", "신유", "임술", "계해"
]

# 월지 배열 (정월=인월부터)
MONTH_ZHI = ["인", "묘", "진", "사", "오", "미", "신", "유", "술", "해", "자", "축"]

# 율리우스 날짜 계산
def gregorian_to_jd(year, month, day, hour = 0, minute = 0)
  if month <= 2
    year -= 1
    month += 12
  end

  a = (year / 100).floor
  b = 2 - a + (a / 4).floor
  fractional_day = day + (hour + minute / 60.0) / 24.0

  (365.25 * (year + 4716)).floor +
    (30.6001 * (month + 1)).floor +
    fractional_day + b - 1524.5
end

# 태양 황경 계산
def get_sun_longitude(jd)
  t = (jd - 2451545.0) / 36525.0
  l0 = (280.46646 + 36000.76983 * t + 0.0003032 * t * t) % 360
  l0 += 360 if l0 < 0
  
  m = (357.52911 + 35999.05029 * t - 0.0001537 * t * t) % 360
  m += 360 if m < 0
  
  m_rad = m * Math::PI / 180
  e = 0.016708634 - 0.000042037 * t - 0.0000001267 * t * t
  
  c = (1.914602 - 0.004817 * t - 0.000014 * t * t) * Math.sin(m_rad) +
      (0.019993 - 0.000101 * t) * Math.sin(2 * m_rad) +
      0.000289 * Math.sin(3 * m_rad)
  
  true_l = (l0 + c) % 360
  true_l += 360 if true_l < 0
  true_l
end

# 입춘 날짜 계산 (태양황경 315도)
def find_ipchun_date(year)
  find_solar_term_date(year, 315)
end

def find_solar_term_date(year, solar_degree)
  target = solar_degree % 360
  jd0 = gregorian_to_jd(year, 1, 1)
  l0 = get_sun_longitude(jd0)
  daily_motion = 0.9856
  
  delta = target - l0
  delta += 360 if delta < 0
  
  jd = jd0 + delta / daily_motion
  iteration = 0
  max_iter = 100
  precision = 0.001
  
  while iteration < max_iter
    l = get_sun_longitude(jd)
    diff = target - l
    diff -= 360 if diff > 180
    diff += 360 if diff < -180
    break if diff.abs < precision
    
    jd += diff / daily_motion
    iteration += 1
  end
  
  Time.at((jd - 2440587.5) * 86400)
end

# 연주 계산
def calculate_year_pillar(year, month, day)
  # 입춘 기준으로 연주 결정
  ipchun = find_ipchun_date(year)
  birth_date = Time.new(year, month, day)
  
  actual_year = birth_date < ipchun ? year - 1 : year
  year_index = ((actual_year - 4) % 60 + 60) % 60
  
  SEXAGENARY_CYCLE[year_index]
end

# 월주 계산
def calculate_month_pillar(year, month, day)
  # 절기 기준으로 월주 결정
  year_ganZhi = calculate_year_pillar(year, month, day)
  year_stem = year_ganZhi[0]
  year_stem_index = CHEONGAN.index(year_stem)
  
  # 절기에 따른 월 번호 계산
  birth_date = Time.new(year, month, day)
  solar_month = get_solar_month(birth_date)
  
  # 월간 계산: 연간에 따라 월간이 결정됨
  base_month_stems = {
    0 => 2,  # 갑년 -> 정월=병인
    1 => 4,  # 을년 -> 정월=무인  
    2 => 6,  # 병년 -> 정월=경인
    3 => 8,  # 정년 -> 정월=임인
    4 => 0,  # 무년 -> 정월=갑인
    5 => 2,  # 기년 -> 정월=병인
    6 => 4,  # 경년 -> 정월=무인
    7 => 6,  # 신년 -> 정월=경인
    8 => 8,  # 임년 -> 정월=임인
    9 => 0   # 계년 -> 정월=갑인
  }
  
  month_stem_index = (base_month_stems[year_stem_index] + solar_month - 1) % 10
  month_branch_index = (solar_month - 1) % 12
  
  CHEONGAN[month_stem_index] + MONTH_ZHI[month_branch_index]
end

# 절기 기준 월 계산
def get_solar_month(birth_date)
  year = birth_date.year
  
  # 절기별 태양황경 (입절 기준)
  solar_terms_degrees = [315, 345, 15, 45, 75, 105, 135, 165, 195, 225, 255, 285]
  
  # 각 월의 절기 날짜들을 계산
  term_dates = []
  solar_terms_degrees.each_with_index do |degree, idx|
    term_year = (degree >= 315 && idx == 0) ? year : year
    term_dates << find_solar_term_date(term_year, degree)
  end
  
  # 생일이 어느 절기 구간에 속하는지 확인
  12.times do |i|
    current_term = term_dates[i]
    next_term = i == 11 ? find_solar_term_date(year + 1, 315) : term_dates[i + 1]
    
    if birth_date >= current_term && birth_date < next_term
      return i + 1  # 1~12월 반환
    end
  end
  
  # 입춘 이전인 경우 12월로 처리
  12
end

# 일주 계산
def calculate_day_pillar(year, month, day)
  jd = gregorian_to_jd(year, month, day)
  index = (jd.floor + 50) % 60
  
  SEXAGENARY_CYCLE[index]
end

# 시주 계산
def calculate_hour_pillar(year, month, day, hour, minute)
  day_pillar = calculate_day_pillar(year, month, day)
  day_stem = day_pillar[0]
  day_stem_index = CHEONGAN.index(day_stem)
  
  # 시지 결정
  hour_branch_index = ((hour + 1) / 2).floor % 12
  
  # 시간 계산
  hour_stem_index = if day_stem_index.even?
                      (day_stem_index * 2 + hour_branch_index) % 10
                    else
                      (day_stem_index * 2 + hour_branch_index + 2) % 10
                    end
  
  CHEONGAN[hour_stem_index] + JIJI[hour_branch_index]
end

# 테스트 실행
year = 1983
month = 5
day = 8
hour = 10
minute = 0

puts "테스트: #{year}년 #{month}월 #{day}일 #{hour}시 출생"
puts "="*50

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
puts "1983년의 입춘: #{find_ipchun_date(1983)}"
puts "5월 6일 (입하): #{find_solar_term_date(1983, 45)}"

# 디버깅 정보
puts "\n디버깅 정보:"
puts "년간지 인덱스: #{((1983 - 4) % 60 + 60) % 60}"
puts "계해의 인덱스: #{SEXAGENARY_CYCLE.index('계해')}"