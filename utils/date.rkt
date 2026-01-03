#lang racket

(require racket/date)

;; 检查日期是否有效（考虑月份的实际天数）
(define (valid-day? year month day)
  (cond
    [(or (= month 1) (= month 3) (= month 5) (= month 7) (= month 8) (= month 10) (= month 12))
     (<= 1 day 31)]
    [(or (= month 4) (= month 6) (= month 9) (= month 11))
     (<= 1 day 30)]
    [(= month 2)
     ;; 检查是否为闰年
     (let ([leap-year? (and (zero? (remainder year 4))
                           (or (not (zero? (remainder year 100)))
                               (zero? (remainder year 400))))])
       (<= 1 day (if leap-year? 29 28)))]
    [else #f]))

;; 规范化日期字符串为 YYYY-MM-DD 格式
(define (normalize-date-string date-str)
  (let ([trimmed-str (string-trim date-str)])
    (if (equal? trimmed-str "")
        #f
        (let ([parts (string-split trimmed-str "-")])
          (if (= (length parts) 3)
              (let* ([year-str (list-ref parts 0)]
                     [month-str (list-ref parts 1)]
                     [day-str (list-ref parts 2)]
                     [year-num (string->number year-str)]
                     [month-num (string->number month-str)]
                     [day-num (string->number day-str)])
                (if (and year-num month-num day-num
                         (<= 1 month-num 12)
                         (<= 1900 year-num 9999)
                         (valid-day? year-num month-num day-num))
                    (format "~a-~a-~a" 
                            (~r year-num #:min-width 4 #:pad-string "0")
                            (~r month-num #:min-width 2 #:pad-string "0")
                            (~r day-num #:min-width 2 #:pad-string "0"))
                    #f))
              #f)))))    
;; 获取当前日期的字符串表示 (YYYY-MM-DD)
(define (get-current-date-string)
  (let ([today (current-date)])
    (format "~a-~a-~a" 
            (date-year today)
            (~r (date-month today) #:min-width 2 #:pad-string "0")
            (~r (date-day today) #:min-width 2 #:pad-string "0"))))

;; 格式化日期显示 (YYYY-MM-DD -> MM月DD日)
(define (format-date-for-display date-str)
  (if (and date-str (string? date-str) (not (equal? date-str "")))
      (let ([parts (string-split date-str "-")])
        (if (= (length parts) 3)
            (let ([month (string->number (list-ref parts 1))]
                  [day (string->number (list-ref parts 2))])
              (if (and month day)
                  (format "~a月~a日" month day)
                  date-str))
            date-str))
      ""))

;; 检查日期是否为今天
(define (is-today? date-str)
  (equal? date-str (get-current-date-string)))

;; 计算两个日期之间的天数差
(define (date-diff date-str1 date-str2)
  (define (date-string->seconds date-str)
    (if (and (string? date-str) (not (equal? date-str "")))
        (let ([parts (string-split date-str "-")])
          (if (= (length parts) 3)
              (let* ([year (string->number (list-ref parts 0))]
                     [month (string->number (list-ref parts 1))]
                     [day (string->number (list-ref parts 2))]
                     [date-struct (seconds->date 0 #f)])
                (if (and year month day)
                    (date->seconds (struct-copy date date-struct
                                               [year year]
                                               [month month]
                                               [day day]
                                               [hour 0]
                                               [minute 0]
                                               [second 0]))
                    0))
              0))
        0))
  
  (define seconds1 (date-string->seconds date-str1))
  (define seconds2 (date-string->seconds date-str2))
  (quotient (abs (- seconds1 seconds2)) (* 60 60 24)))

;; 解析日期字符串，支持相对时间和精确时间格式
(define (parse-date-string date-str)
  (let ([trimmed-str (string-trim date-str)])
    (if (equal? trimmed-str "")
        #f
        (cond
          ;; 相对时间格式：+Nd, +Nm, +Nh, +Nw, +NM
          [(regexp-match #rx"^\\+([0-9]+)([dmhwM])$" trimmed-str)
           => (lambda (match)
                (define num (string->number (second match)))
                (define unit (third match))
                (define now (current-date))
                
                (define new-date
                  (case unit
                    [("m") ; 分钟
                     (seconds->date (+ (date->seconds now) (* num 60)))]
                    [("h") ; 小时
                     (seconds->date (+ (date->seconds now) (* num 3600)))]
                    [("d") ; 天
                     (seconds->date (+ (date->seconds now) (* num 86400)))]
                    [("w") ; 周
                     (seconds->date (+ (date->seconds now) (* num 604800)))]
                    [("M") ; 月
                     (define new-month (+ (date-month now) num))
                     (define year-offset (quotient (- new-month 1) 12))
                     (define final-month (+ 1 (remainder (- new-month 1) 12)))
                     (define final-year (+ (date-year now) year-offset))
                     ;; 处理月份天数问题，确保日期有效
                     (define final-day (min (date-day now) 
                                           (if (member final-month '(1 3 5 7 8 10 12)) 31
                                               (if (member final-month '(4 6 9 11)) 30
                                                   ;; 二月
                                                   (if (and (zero? (remainder final-year 4))
                                                            (or (not (zero? (remainder final-year 100)))
                                                                (zero? (remainder final-year 400))))
                                                       29
                                                       28)))))
                     (struct-copy date now
                                  (year final-year)
                                  (month final-month)
                                  (day final-day))]
                    [else now]))
                
                ;; 格式化为 YYYY-MM-DD
                (format "~a-~a-~a" 
                        (date-year new-date)
                        (~r (date-month new-date) #:min-width 2 #:pad-string "0")
                        (~r (date-day new-date) #:min-width 2 #:pad-string "0")))]
          
          ;; 精确时间格式：@time 或 @time day
          [(regexp-match #rx"^@([0-9]+)(:[0-9]+)?([ap]m)?(.*)$" trimmed-str)
           => (lambda (match)
                (define hour (string->number (second match)))
                (define minute (if (third match) (string->number (substring (third match) 1)) 0))
                (define am-pm (fourth match))
                (define day-spec (string-trim (fifth match)))
                (define now (current-date))
                
                ;; 处理上午/下午
                (define final-hour
                  (cond
                    [(and am-pm (string=? am-pm "am"))
                     (if (= hour 12) 0 hour)]
                    [(and am-pm (string=? am-pm "pm"))
                     (if (= hour 12) 12 (+ hour 12))]
                    [else hour]))
                
                ;; 计算目标日期
                (define target-date
                  (cond
                    [(or (equal? day-spec "tomorrow") (equal? day-spec "tmw"))
                     ;; 明天
                     (seconds->date (+ (date->seconds now) 86400))]
                    [(and (not (equal? day-spec ""))
                          (member (string-downcase day-spec) '("mon" "tue" "wed" "thu" "fri" "sat" "sun")))
                     ;; 本周的某一天
                     (define day-names '("mon" "tue" "wed" "thu" "fri" "sat" "sun"))
                     (define target-day-index (index-of day-names (string-downcase day-spec)))
                     (define current-day-index (date-week-day now))
                     (define day-diff (+ (- target-day-index current-day-index) 
                                        (if (<= target-day-index current-day-index) 7 0)))
                     (seconds->date (+ (date->seconds now) (* day-diff 86400)))]
                    [else
                     ;; 今天
                     now]))
                
                ;; 检查时间是否已过，如果已过则使用明天
                (define final-date
                  (if (and (= (date-year target-date) (date-year now))
                           (= (date-month target-date) (date-month now))
                           (= (date-day target-date) (date-day now))
                           (> (date->seconds now) 
                              (date->seconds (struct-copy date now
                                                         (hour final-hour)
                                                         (minute minute)
                                                         (second 0)))))
                      ;; 时间已过，使用明天
                      (seconds->date (+ (date->seconds target-date) 86400))
                      ;; 时间未过，使用今天
                      target-date))
                
                ;; 格式化为 YYYY-MM-DD
                (format "~a-~a-~a" 
                        (date-year final-date)
                        (~r (date-month final-date) #:min-width 2 #:pad-string "0")
                        (~r (date-day final-date) #:min-width 2 #:pad-string "0")))]
          
          ;; 其他格式，使用原有函数处理
          [else (normalize-date-string trimmed-str)]))))

;; 验证日期格式是否正确
(define (valid-date? date-str)
  (if (and date-str (string? date-str) (not (equal? date-str "")))
      (let ([normalized (parse-date-string date-str)])
        (not (boolean? normalized)))
      #t)) ; 空字符串也是有效的

(provide normalize-date-string
         parse-date-string
         get-current-date-string
         format-date-for-display
         is-today?
         valid-date?
         date-diff)