require 'date'

class ZodiacByYear
  # 1920년부터 2030년까지 음력 설날(Chinese New Year) 기준일 테이블
  LUNAR_NEW_YEAR = {
    1920 => Date.new(1920, 2, 20),  1921 => Date.new(1921, 2, 8),
    1922 => Date.new(1922, 1, 28),  1923 => Date.new(1923, 2, 16),
    1924 => Date.new(1924, 2, 5),   1925 => Date.new(1925, 1, 24),
    1926 => Date.new(1926, 2, 13),  1927 => Date.new(1927, 2, 2),
    1928 => Date.new(1928, 1, 23),  1929 => Date.new(1929, 2, 10),
    1930 => Date.new(1930, 1, 30),  1931 => Date.new(1931, 2, 17),
    1932 => Date.new(1932, 2, 6),   1933 => Date.new(1933, 1, 26),
    1934 => Date.new(1934, 2, 14),  1935 => Date.new(1935, 2, 4),
    1936 => Date.new(1936, 1, 24),  1937 => Date.new(1937, 2, 11),
    1938 => Date.new(1938, 1, 31),  1939 => Date.new(1939, 2, 19),
    1940 => Date.new(1940, 2, 8),   1941 => Date.new(1941, 1, 27),
    1942 => Date.new(1942, 2, 15),  1943 => Date.new(1943, 2, 4),
    1944 => Date.new(1944, 1, 25),  1945 => Date.new(1945, 2, 13),
    1946 => Date.new(1946, 2, 1),   1947 => Date.new(1947, 1, 22),
    1948 => Date.new(1948, 2, 10),  1949 => Date.new(1949, 1, 29),
    1950 => Date.new(1950, 2, 17),  1951 => Date.new(1951, 2, 6),
    1952 => Date.new(1952, 1, 27),  1953 => Date.new(1953, 2, 14),
    1954 => Date.new(1954, 2, 3),   1955 => Date.new(1955, 1, 24),
    1956 => Date.new(1956, 2, 12),  1957 => Date.new(1957, 1, 31),
    1958 => Date.new(1958, 2, 18),  1959 => Date.new(1959, 2, 8),
    1960 => Date.new(1960, 1, 28),  1961 => Date.new(1961, 2, 15),
    1962 => Date.new(1962, 2, 5),   1963 => Date.new(1963, 1, 25),
    1964 => Date.new(1964, 2, 13),  1965 => Date.new(1965, 2, 2),
    1966 => Date.new(1966, 1, 21),  1967 => Date.new(1967, 2, 9),
    1968 => Date.new(1968, 1, 30),  1969 => Date.new(1969, 2, 17),
    1970 => Date.new(1970, 2, 6),   1971 => Date.new(1971, 1, 27),
    1972 => Date.new(1972, 2, 15),  1973 => Date.new(1973, 2, 3),
    1974 => Date.new(1974, 1, 23),  1975 => Date.new(1975, 2, 11),
    1976 => Date.new(1976, 1, 31),  1977 => Date.new(1977, 2, 18),
    1978 => Date.new(1978, 2, 7),   1979 => Date.new(1979, 1, 28),
    1980 => Date.new(1980, 2, 16),  1981 => Date.new(1981, 2, 5),
    1982 => Date.new(1982, 1, 25),  1983 => Date.new(1983, 2, 13),
    1984 => Date.new(1984, 2, 2),   1985 => Date.new(1985, 2, 20),
    1986 => Date.new(1986, 2, 9),   1987 => Date.new(1987, 1, 29),
    1988 => Date.new(1988, 2, 17),  1989 => Date.new(1989, 2, 6),
    1990 => Date.new(1990, 1, 27),  1991 => Date.new(1991, 2, 15),
    1992 => Date.new(1992, 2, 4),   1993 => Date.new(1993, 1, 23),
    1994 => Date.new(1994, 2, 10),  1995 => Date.new(1995, 1, 31),
    1996 => Date.new(1996, 2, 19),  1997 => Date.new(1997, 2, 7),
    1998 => Date.new(1998, 1, 28),  1999 => Date.new(1999, 2, 16),
    2000 => Date.new(2000, 2, 5),   2001 => Date.new(2001, 1, 24),
    2002 => Date.new(2002, 2, 12),  2003 => Date.new(2003, 2, 1),
    2004 => Date.new(2004, 1, 22),  2005 => Date.new(2005, 2, 9),
    2006 => Date.new(2006, 1, 29),  2007 => Date.new(2007, 2, 18),
    2008 => Date.new(2008, 2, 7),   2009 => Date.new(2009, 1, 26),
    2010 => Date.new(2010, 2, 14),  2011 => Date.new(2011, 2, 3),
    2012 => Date.new(2012, 1, 23),  2013 => Date.new(2013, 2, 10),
    2014 => Date.new(2014, 1, 31),  2015 => Date.new(2015, 2, 19),
    2016 => Date.new(2016, 2, 8),   2017 => Date.new(2017, 1, 28),
    2018 => Date.new(2018, 2, 16),  2019 => Date.new(2019, 2, 5),
    2020 => Date.new(2020, 1, 25),  2021 => Date.new(2021, 2, 12),
    2022 => Date.new(2022, 2, 1),   2023 => Date.new(2023, 1, 22),
    2024 => Date.new(2024, 2, 10),  2025 => Date.new(2025, 1, 29),
    2026 => Date.new(2026, 2, 17),  2027 => Date.new(2027, 2, 6),
    2028 => Date.new(2028, 1, 26),  2029 => Date.new(2029, 2, 13),
    2030 => Date.new(2030, 2, 3)
  }

  # 띠 배열 (한국어)
  ZODIAC_ANIMALS = %w[쥐 소 호랑이 토끼 용 뱀 말 양 원숭이 닭 개 돼지]

  def initialize(month, day)
    @month = month
    @day = day
  end

  # 연도별 띠를 반환하는 메서드
  def zodiac_by_years
    result = {}
    (1920..2030).each do |year|
      result[year] = zodiac_for_year(year)
    end
    result
  end

  # 특정 연도의 띠를 반환하는 메서드
  def zodiac_for_year(year)
    date = Date.new(year, @month, @day)
    lunar_new_year = LUNAR_NEW_YEAR[year]
    
    # 음력 설날 이전이면 전년도 기준, 이후면 해당 연도 기준
    zodiac_year = date < lunar_new_year ? year - 1 : year
    ZODIAC_ANIMALS[(zodiac_year - 4) % 12]
  end

  private

  # 특정 연도의 음력 설날 날짜를 반환
  def lunar_new_year(year)
    LUNAR_NEW_YEAR[year]
  end
end