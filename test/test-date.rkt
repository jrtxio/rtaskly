#lang racket

(require rackunit
         rackunit/text-ui
         "../utils/date.rkt")

;; 定义测试套件
(define date-tests
  (test-suite
   "日期工具测试"
   
   ;; 测试 normalize-date-string 函数
   (test-case "测试日期格式规范化" 
     ;; 正常情况
     (check-equal? (normalize-date-string "2023-01-01") "2023-01-01")
     (check-equal? (normalize-date-string "2023-1-1") "2023-01-01")
     (check-equal? (normalize-date-string " 2023-01-01 ") "2023-01-01")
     
     ;; 边界情况 - 年份
     (check-equal? (normalize-date-string "1900-01-01") "1900-01-01")
     (check-equal? (normalize-date-string "9999-12-31") "9999-12-31")
     (check-false (normalize-date-string "1899-01-01"))
     (check-false (normalize-date-string "10000-01-01"))
     
     ;; 边界情况 - 月份
     (check-equal? (normalize-date-string "2023-01-01") "2023-01-01")
     (check-equal? (normalize-date-string "2023-12-31") "2023-12-31")
     (check-false (normalize-date-string "2023-00-01"))
     (check-false (normalize-date-string "2023-13-01"))
     
     ;; 边界情况 - 日期
     (check-equal? (normalize-date-string "2023-01-01") "2023-01-01")
     (check-equal? (normalize-date-string "2023-01-31") "2023-01-31")
     (check-false (normalize-date-string "2023-01-00"))
     (check-false (normalize-date-string "2023-01-32"))
     
     ;; 无效格式
     (check-false (normalize-date-string "2023/01/01"))
     (check-false (normalize-date-string "2023.01.01"))
     (check-false (normalize-date-string "2023_01_01"))
     (check-false (normalize-date-string "20230101"))
     (check-false (normalize-date-string "2023-01"))
     (check-false (normalize-date-string "01-01"))
     
     ;; 特殊情况
     (check-false (normalize-date-string ""))
     (check-false (normalize-date-string "invalid-date"))
     (check-false (normalize-date-string "2023-02-30")) ; 无效日期（2月没有30日）
     (check-false (normalize-date-string "2023-04-31")) ; 无效日期（4月只有30天）
     )
   
   ;; 测试 get-current-date-string 函数
   (test-case "测试当前日期字符串生成" 
     (define date-str (get-current-date-string))
     (check-pred string? date-str)
     (check-equal? (length (string-split date-str "-")) 3)
     ;; 检查格式是否为 YYYY-MM-DD
     (check-regexp-match #px"^\\d{4}-\\d{2}-\\d{2}$" date-str)
     
     ;; 检查日期范围
     (define parts (string-split date-str "-"))
     (define year (string->number (list-ref parts 0)))
     (define month (string->number (list-ref parts 1)))
     (define day (string->number (list-ref parts 2)))
     
     (check-true (<= 1900 year 9999))
     (check-true (<= 1 month 12))
     (check-true (<= 1 day 31))
     )
   
   ;; 测试 format-date-for-display 函数
   (test-case "测试日期显示格式化" 
     ;; 正常情况
     (check-equal? (format-date-for-display "2023-01-01") "1月1日")
     (check-equal? (format-date-for-display "2023-12-31") "12月31日")
     (check-equal? (format-date-for-display "2023-06-15") "6月15日")
     
     ;; 边界情况
     (check-equal? (format-date-for-display "1900-01-01") "1月1日")
     (check-equal? (format-date-for-display "9999-12-31") "12月31日")
     
     ;; 特殊情况
     (check-equal? (format-date-for-display "") "")
     (check-equal? (format-date-for-display #f) "")
     (check-equal? (format-date-for-display "invalid-date") "invalid-date")
     (check-equal? (format-date-for-display "2023") "2023")
     (check-equal? (format-date-for-display "2023-01") "2023-01")
     )
   
   ;; 测试 is-today? 函数
   (test-case "测试日期是否为今天" 
     (define today (get-current-date-string))
     (check-true (is-today? today))
     (check-true (is-today? (string-trim today)))
     
     ;; 昨天和明天
     (define parts (string-split today "-"))
     (define year (string->number (list-ref parts 0)))
     (define month (string->number (list-ref parts 1)))
     (define day (string->number (list-ref parts 2)))
     
     (define yesterday (format "~a-~a-~a" year month (if (> day 1) (- day 1) 1)))
     (check-false (is-today? yesterday))
     
     (define tomorrow (format "~a-~a-~a" year month (if (< day 30) (+ day 1) 30)))
     (check-false (is-today? tomorrow))
     
     ;; 无效日期
     (check-false (is-today? ""))
     (check-false (is-today? #f))
     (check-false (is-today? "invalid-date"))
     )
   
   ;; 测试 valid-date? 函数
   (test-case "测试日期格式有效性" 
     ;; 有效日期
     (check-true (valid-date? "2023-01-01"))
     (check-true (valid-date? "2023-1-1"))
     (check-true (valid-date? "1900-01-01"))
     (check-true (valid-date? "9999-12-31"))
     
     ;; 特殊情况
     (check-true (valid-date? ""))
     (check-true (valid-date? #f))
     
     ;; 无效日期
     (check-false (valid-date? "2023/01/01"))
     (check-false (valid-date? "2023-13-01"))
     (check-false (valid-date? "2023-01-32"))
     (check-false (valid-date? "2023-02-30"))
     (check-false (valid-date? "1899-01-01"))
     (check-false (valid-date? "10000-01-01"))
     (check-false (valid-date? "invalid-date"))
     (check-false (valid-date? "2023-01"))
     (check-false (valid-date? "01-01"))
     (check-false (valid-date? "2023"))
     )
   
   ;; 测试 parse-date-string 函数 - 相对时间
   (test-case "测试相对时间格式解析" 
     ;; 获取今天和明天的日期
     (define today (get-current-date-string))
     (define today-parts (string-split today "-"))
     (define today-year (string->number (list-ref today-parts 0)))
     (define today-month (string->number (list-ref today-parts 1)))
     (define today-day (string->number (list-ref today-parts 2)))
     
     (define tomorrow-day (if (< today-day 31) (+ today-day 1) 1))
     (define tomorrow-month (if (< today-day 31) today-month (+ today-month 1)))
     (define tomorrow-year (if (< today-month 12) today-year (+ today-year 1)))
     (define tomorrow (format "~a-~a-~a" 
                               tomorrow-year
                               (~r tomorrow-month #:min-width 2 #:pad-string "0")
                               (~r tomorrow-day #:min-width 2 #:pad-string "0")))
     
     ;; 测试 +1d (1天后)
     (check-equal? (parse-date-string "+1d") tomorrow)
     
     ;; 测试 +30m (30分钟后，应该还是今天)
     (check-equal? (parse-date-string "+30m") today)
     
     ;; 测试 +2h (2小时后，应该还是今天)
     (check-equal? (parse-date-string "+2h") today)
     
     ;; 测试 +1w (1周后)
     (check-not-false (parse-date-string "+1w"))
     
     ;; 测试 +6M (6个月后)
     (check-not-false (parse-date-string "+6M"))
     )
   
   ;; 测试 parse-date-string 函数 - 精确时间
   (test-case "测试精确时间格式解析" 
     ;; 获取今天和明天的日期
     (define today (get-current-date-string))
     (define today-parts (string-split today "-"))
     (define today-year (string->number (list-ref today-parts 0)))
     (define today-month (string->number (list-ref today-parts 1)))
     (define today-day (string->number (list-ref today-parts 2)))
     
     (define tomorrow-day (if (< today-day 31) (+ today-day 1) 1))
     (define tomorrow-month (if (< today-day 31) today-month (+ today-month 1)))
     (define tomorrow-year (if (< today-month 12) today-year (+ today-year 1)))
     (define tomorrow (format "~a-~a-~a" 
                               tomorrow-year
                               (~r tomorrow-month #:min-width 2 #:pad-string "0")
                               (~r tomorrow-day #:min-width 2 #:pad-string "0")))
     
     ;; 测试 @10am (应该返回今天或明天)
     (check-not-false (parse-date-string "@10am"))
     
     ;; 测试 @10:30pm (应该返回今天或明天)
     (check-not-false (parse-date-string "@10:30pm"))
     
     ;; 测试 @22:30 (应该返回今天或明天)
     (check-not-false (parse-date-string "@22:30"))
     
     ;; 测试 @10am tomorrow (应该返回明天)
     (check-equal? (parse-date-string "@10am tomorrow") tomorrow)
     
     ;; 测试 @10am tmw (应该返回明天，缩写形式)
     (check-equal? (parse-date-string "@10am tmw") tomorrow)
     
     ;; 测试 @8pm mon (应该返回有效日期)
     (check-not-false (parse-date-string "@8pm mon"))
     )
   
   ;; 测试 parse-date-string 函数 - 兼容性
   (test-case "测试日期格式兼容性" 
     ;; 确保原有格式仍然有效
     (check-equal? (parse-date-string "2025-08-07") "2025-08-07")
     (check-equal? (parse-date-string "2025-01-01") "2025-01-01")
     )
   ))

;; 运行测试套件
(run-tests date-tests)