require 'sinatra'
require 'sinatra/reloader' if development?
require 'sqlite3'
require 'json'
require 'securerandom'

# Configure static file serving
set :public_folder, File.dirname(__FILE__) + '/public'
set :static, true

# Explicit route for PNG files (fallback if nginx doesn't work)
get '/*.png' do |filename|
  send_file File.join(settings.public_folder, "#{filename}.png")
end

# Database setup
def initialize_database
  return @db if @db

  # 데이터베이스 파일 경로 설정
  db_path = (ENV['RACK_ENV'] == 'production' || ENV['RAILS_ENV'] == 'production') ? "/tmp/saju.db" : "saju.db"
  @db = SQLite3::Database.new(db_path)
  
  # WAL 모드로 설정 (동시 접근 개선)
  @db.execute("PRAGMA journal_mode=WAL;")
  @db.execute("PRAGMA synchronous=NORMAL;")
  @db.execute("PRAGMA cache_size=1000;")
  @db.execute("PRAGMA temp_store=memory;")
  
  # 데이터베이스 락 처리를 위한 재시도 로직
  retries = 0
  max_retries = 5
  
  begin
    # 먼저 기존 테이블 구조 확인
    existing_columns = @db.execute("PRAGMA table_info(users);")
    has_uuid_column = existing_columns.any? { |col| col[1] == 'uuid' }
    
    if !has_uuid_column
      # uuid 컬럼이 없으면 추가
      @db.execute "ALTER TABLE users ADD COLUMN uuid TEXT;"
      
      # 기존 레코드에 UUID 할당
      existing_users = @db.execute("SELECT id FROM users WHERE uuid IS NULL;")
      existing_users.each do |user|
        uuid = SecureRandom.uuid
        @db.execute("UPDATE users SET uuid = ? WHERE id = ?", [uuid, user[0]])
      end
    end
  rescue SQLite3::SQLException => e
    if e.message.include?("no such table")
      # 테이블이 없으면 새로 생성
      @db.execute <<-SQL
        CREATE TABLE users (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          uuid TEXT UNIQUE NOT NULL,
          name TEXT NOT NULL,
          gender TEXT NOT NULL,
          birth_year INTEGER NOT NULL,
          birth_month INTEGER NOT NULL,
          birth_day INTEGER NOT NULL,
          birth_hour INTEGER NOT NULL,
          created_at DATETIME DEFAULT CURRENT_TIMESTAMP
        );
      SQL
    elsif e.message.include?("database is locked") && retries < max_retries
      retries += 1
      sleep(0.1 * retries)  # 지수 백오프
      retry
    end
  end

  # UUID 인덱스 생성
  begin
    @db.execute "CREATE INDEX IF NOT EXISTS idx_uuid ON users(uuid);"
  rescue SQLite3::SQLException => e
    # 인덱스 생성 실패는 무시 (이미 존재할 수 있음)
  end
  
  @db
end

# 전역 데이터베이스 연결
DB = initialize_database

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

# 십신 매핑
TEN_GOD_STEMS = {
  "갑" => { "갑" => "비견", "을" => "겁재", "병" => "식신", "정" => "상관", "무" => "편재", "기" => "정재", "경" => "편관", "신" => "정관", "임" => "편인", "계" => "정인" },
  "을" => { "갑" => "겁재", "을" => "비견", "병" => "상관", "정" => "식신", "무" => "정재", "기" => "편재", "경" => "정관", "신" => "편관", "임" => "정인", "계" => "편인" },
  "병" => { "갑" => "편인", "을" => "정인", "병" => "비견", "정" => "겁재", "무" => "식신", "기" => "상관", "경" => "편재", "신" => "정재", "임" => "편관", "계" => "정관" },
  "정" => { "갑" => "정인", "을" => "편인", "병" => "겁재", "정" => "비견", "무" => "상관", "기" => "식신", "경" => "정재", "신" => "편재", "임" => "정관", "계" => "편관" },
  "무" => { "갑" => "편관", "을" => "정관", "병" => "편인", "정" => "정인", "무" => "비견", "기" => "겁재", "경" => "식신", "신" => "상관", "임" => "편재", "계" => "정재" },
  "기" => { "갑" => "정관", "을" => "편관", "병" => "정인", "정" => "편인", "무" => "겁재", "기" => "비견", "경" => "상관", "신" => "식신", "임" => "정재", "계" => "편재" },
  "경" => { "갑" => "편재", "을" => "정재", "병" => "편관", "정" => "정관", "무" => "편인", "기" => "정인", "경" => "비견", "신" => "겁재", "임" => "식신", "계" => "상관" },
  "신" => { "갑" => "정재", "을" => "편재", "병" => "정관", "정" => "편관", "무" => "정인", "기" => "편인", "경" => "겁재", "신" => "비견", "임" => "상관", "계" => "식신" },
  "임" => { "갑" => "식신", "을" => "상관", "병" => "편재", "정" => "정재", "무" => "편관", "기" => "정관", "경" => "편인", "신" => "정인", "임" => "비견", "계" => "겁재" },
  "계" => { "갑" => "상관", "을" => "식신", "병" => "정재", "정" => "편재", "무" => "정관", "기" => "편관", "경" => "정인", "신" => "편인", "임" => "겁재", "계" => "비견" }
}

# 십신 매핑 - 지지
TEN_GOD_BRANCHES = {
  "갑" => { "자" => "정인", "축" => "정재", "인" => "비견", "묘" => "겁재", "진" => "편재", "사" => "식신", "오" => "상관", "미" => "정재", "신" => "편관", "유" => "정관", "술" => "편재", "해" => "편인" },
  "을" => { "자" => "편인", "축" => "편재", "인" => "겁재", "묘" => "비견", "진" => "정재", "사" => "상관", "오" => "식신", "미" => "편재", "신" => "정관", "유" => "편관", "술" => "정재", "해" => "정인" },
  "병" => { "자" => "정관", "축" => "상관", "인" => "편인", "묘" => "정인", "진" => "식신", "사" => "비견", "오" => "겁재", "미" => "상관", "신" => "편재", "유" => "정재", "술" => "식신", "해" => "편관" },
  "정" => { "자" => "편관", "축" => "식신", "인" => "정인", "묘" => "편인", "진" => "상관", "사" => "겁재", "오" => "비견", "미" => "식신", "신" => "정재", "유" => "편재", "술" => "상관", "해" => "정관" },
  "무" => { "자" => "정재", "축" => "겁재", "인" => "편관", "묘" => "정관", "진" => "비견", "사" => "편인", "오" => "정인", "미" => "겁재", "신" => "식신", "유" => "상관", "술" => "비견", "해" => "편재" },
  "기" => { "자" => "편재", "축" => "비견", "인" => "정관", "묘" => "편관", "진" => "겁재", "사" => "정인", "오" => "편인", "미" => "비견", "신" => "상관", "유" => "식신", "술" => "겁재", "해" => "정재" },
  "경" => { "자" => "상관", "축" => "정인", "인" => "편재", "묘" => "정재", "진" => "편인", "사" => "편관", "오" => "정관", "미" => "정인", "신" => "비견", "유" => "겁재", "술" => "편인", "해" => "식신" },
  "신" => { "자" => "식신", "축" => "편인", "인" => "정재", "묘" => "편재", "진" => "정인", "사" => "정관", "오" => "편관", "미" => "편인", "신" => "겁재", "유" => "비견", "술" => "정인", "해" => "상관" },
  "임" => { "자" => "겁재", "축" => "정관", "인" => "식신", "묘" => "상관", "진" => "편관", "사" => "편재", "오" => "정재", "미" => "정관", "신" => "편인", "유" => "정인", "술" => "편관", "해" => "비견" },
  "계" => { "자" => "비견", "축" => "편관", "인" => "상관", "묘" => "식신", "진" => "정관", "사" => "정재", "오" => "편재", "미" => "편관", "신" => "정인", "유" => "편인", "술" => "정관", "해" => "겁재" }
}

# 12운성 매핑
TWELVE_UNSEONG = {
  "갑" => { "자" => "목욕", "축" => "관대", "인" => "건록", "묘" => "제왕", "진" => "쇠", "사" => "병", "오" => "사", "미" => "묘", "신" => "절", "유" => "태", "술" => "양", "해" => "장생" },
  "을" => { "자" => "병", "축" => "쇠", "인" => "제왕", "묘" => "건록", "진" => "관대", "사" => "목욕", "오" => "장생", "미" => "양", "신" => "태", "유" => "절", "술" => "묘", "해" => "사" },
  "병" => { "자" => "태", "축" => "양", "인" => "장생", "묘" => "목욕", "진" => "관대", "사" => "건록", "오" => "제왕", "미" => "쇠", "신" => "병", "유" => "사", "술" => "묘", "해" => "절" },
  "정" => { "자" => "절", "축" => "묘", "인" => "사", "묘" => "병", "진" => "쇠", "사" => "제왕", "오" => "건록", "미" => "관대", "신" => "목욕", "유" => "장생", "술" => "양", "해" => "태" },
  "무" => { "자" => "태", "축" => "양", "인" => "장생", "묘" => "목욕", "진" => "관대", "사" => "건록", "오" => "제왕", "미" => "쇠", "신" => "병", "유" => "사", "술" => "묘", "해" => "절" },
  "기" => { "자" => "절", "축" => "묘", "인" => "사", "묘" => "병", "진" => "쇠", "사" => "제왕", "오" => "건록", "미" => "관대", "신" => "목욕", "유" => "장생", "술" => "양", "해" => "태" },
  "경" => { "자" => "사", "축" => "묘", "인" => "절", "묘" => "태", "진" => "양", "사" => "장생", "오" => "목욕", "미" => "관대", "신" => "건록", "유" => "제왕", "술" => "쇠", "해" => "병" },
  "신" => { "자" => "장생", "축" => "양", "인" => "태", "묘" => "절", "진" => "묘", "사" => "사", "오" => "병", "미" => "쇠", "신" => "제왕", "유" => "건록", "술" => "관대", "해" => "목욕" },
  "임" => { "자" => "제왕", "축" => "쇠", "인" => "병", "묘" => "사", "진" => "묘", "사" => "절", "오" => "태", "미" => "양", "신" => "장생", "유" => "목욕", "술" => "관대", "해" => "건록" },
  "계" => { "자" => "건록", "축" => "관대", "인" => "목욕", "묘" => "장생", "진" => "양", "사" => "태", "오" => "절", "미" => "묘", "신" => "사", "유" => "병", "술" => "쇠", "해" => "제왕" }
}

# Helper methods
helpers do
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
      0 => 2,  # 갑년 -> 정월=정인
      1 => 4,  # 을년 -> 정월=무인  
      2 => 6,  # 병년 -> 정월=경인
      3 => 8,  # 정년 -> 정월=임인
      4 => 0,  # 무년 -> 정월=갑인
      5 => 2,  # 기년 -> 정월=정인
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

  # 용신 계산 함수
  def calculate_yongshin(day_stem)
    case day_stem
    when "갑", "을"
      "수(水)"
    when "병", "정"
      "목(木)"
    when "무", "기"
      "화(火)"
    when "경", "신"
      "토(土)"
    when "임", "계"
      "금(金)"
    else
      "알 수 없음"
    end
  end
end

# Routes
get '/' do
  erb :birth_input
end

get '/birth' do
  erb :birth_input
end

post '/calculate' do
  name = params[:name]
  gender = params[:gender]
  year = params[:year].to_i
  month = params[:month].to_i
  day = params[:day].to_i
  hour = params[:hour].to_i
  minute = 0  # 분은 0으로 설정
  
  # UUID 생성
  uuid = SecureRandom.uuid
  
  # Save to database
  DB.execute("INSERT INTO users (uuid, name, gender, birth_year, birth_month, birth_day, birth_hour) VALUES (?, ?, ?, ?, ?, ?, ?)",
    [uuid, name, gender, year, month, day, hour])
  
  redirect "/result/#{uuid}"
end

get '/result/:uuid' do
  uuid = params[:uuid]
  
  # UUID 형식 검증 (RFC 4122 형식)
  unless uuid.match?(/\A[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}\z/i)
    redirect '/'
    return
  end
  
  user = DB.execute("SELECT * FROM users WHERE uuid = ?", uuid).first
  
  if user
    @name = user[2]    # uuid 컬럼이 추가되어 인덱스 변경
    @gender = user[3]
    @year = user[4]
    @month = user[5]
    @day = user[6]
    @hour = user[7]
    @minute = 0
    
    # 정확한 사주 계산
    @year_pillar = calculate_year_pillar(@year, @month, @day)
    @month_pillar = calculate_month_pillar(@year, @month, @day)
    @day_pillar = calculate_day_pillar(@year, @month, @day)
    @hour_pillar = calculate_hour_pillar(@year, @month, @day, @hour, @minute)
    
    # 일간 추출
    @day_stem = @day_pillar[0]
    
    # 각 기둥의 천간과 지지 분리
    @year_stem = @year_pillar[0]
    @year_branch = @year_pillar[1]
    @month_stem = @month_pillar[0]
    @month_branch = @month_pillar[1]
    @day_branch = @day_pillar[1]
    @hour_stem = @hour_pillar[0]
    @hour_branch = @hour_pillar[1]
    
    # 십신 계산
    @year_stem_ten_god = TEN_GOD_STEMS[@day_stem][@year_stem]
    @month_stem_ten_god = TEN_GOD_STEMS[@day_stem][@month_stem]
    @hour_stem_ten_god = TEN_GOD_STEMS[@day_stem][@hour_stem]
    
    @year_branch_ten_god = TEN_GOD_BRANCHES[@day_stem][@year_branch]
    @month_branch_ten_god = TEN_GOD_BRANCHES[@day_stem][@month_branch]
    @day_branch_ten_god = TEN_GOD_BRANCHES[@day_stem][@day_branch]
    @hour_branch_ten_god = TEN_GOD_BRANCHES[@day_stem][@hour_branch]
    
    # 12운성 계산
    @year_unseong = TWELVE_UNSEONG[@day_stem][@year_branch]
    @month_unseong = TWELVE_UNSEONG[@day_stem][@month_branch]
    @day_unseong = TWELVE_UNSEONG[@day_stem][@day_branch]
    @hour_unseong = TWELVE_UNSEONG[@day_stem][@hour_branch]
    
    # 용신 판단
    @yongshin = calculate_yongshin(@day_stem)
    
    erb :result
  else
    redirect '/'
  end
end