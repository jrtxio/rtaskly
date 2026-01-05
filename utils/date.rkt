#lang racket

(require racket/date
         db
         (only-in db sql-null?))

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

;; 格式化日期显示 (YYYY-MM-DD -> YYYY年MM月DD日)
(define (format-date-for-display date-str)
  (if (and date-str (not (sql-null? date-str)) (string? date-str) (not (equal? date-str "")))
      (let ([date-part (if (string-contains? date-str " ")
                           (first (string-split date-str " "))
                           date-str)]
            [time-part (if (string-contains? date-str " ")
                           (second (string-split date-str " "))
                           #f)])
        (let ([parts (string-split date-part "-")])
          (if (= (length parts) 3)
              (let ([year (string->number (list-ref parts 0))]
                    [month (string->number (list-ref parts 1))]
                    [day (string->number (list-ref parts 2))])
                (if (and year month day)
                    (if time-part
                        (format "~a年~a月~a日 ~a" year month day time-part)
                        (format "~a年~a月~a日" year month day))
                    date-str))
              date-str)))
      ""))

;; 检查日期是否为今天
(define (is-today? date-str)
  (if (or (not date-str) (sql-null? date-str))
      #f
      (let ([date-part (if (string-contains? date-str " ")
                           (first (string-split date-str " "))
                           date-str)])
        (equal? date-part (get-current-date-string)))))

;; 日期字符串转换为秒数的辅助函数
(define (date-string->seconds date-str)
  (if (and date-str (string? date-str) (not (equal? date-str "")))
      (let ([date-part (if (string-contains? date-str " ")
                           (first (string-split date-str " "))
                           date-str)]
            [time-part (if (string-contains? date-str " ")
                           (second (string-split date-str " "))
                           "00:00")])
        (let ([date-parts (string-split date-part "-")]
              [time-parts (string-split time-part ":")])
          (if (and (= (length date-parts) 3) (= (length time-parts) 2))
              (let* ([year (string->number (list-ref date-parts 0))]
                     [month (string->number (list-ref date-parts 1))]
                     [day (string->number (list-ref date-parts 2))]
                     [hour (string->number (list-ref time-parts 0))]
                     [minute (string->number (list-ref time-parts 1))]
                     [date-struct (seconds->date 0 #f)])
                (if (and year month day hour minute)
                    (date->seconds (struct-copy date date-struct
                                               (year year)
                                               (month month)
                                               (day day)
                                               (hour hour)
                                               (minute minute)
                                               (second 0)))
                    0))
              0)))
      0))

;; 计算两个日期之间的天数差
(define (date-diff date-str1 date-str2)
  (if (or (sql-null? date-str1) (sql-null? date-str2) (not date-str1) (not date-str2) (equal? date-str1 "") (equal? date-str2 ""))
      0
      (let ([seconds1 (date-string->seconds date-str1)]
            [seconds2 (date-string->seconds date-str2)])
        (quotient (abs (- seconds1 seconds2)) (* 60 60 24)))))

;; 获取月份的最大天数
(define (get-month-max-day year month)
  (cond
    [(member month '(1 3 5 7 8 10 12)) 31]
    [(member month '(4 6 9 11)) 30]
    [(and (zero? (remainder year 4))
          (or (not (zero? (remainder year 100)))
              (zero? (remainder year 400)))) 29]
    [else 28]))

;; 解析相对时间格式
(define (parse-relative-time num unit)
  (let ([now (current-date)]
        [num (string->number num)])
    (cond
      [(string=? unit "m")
       ;; 分钟
       (seconds->date (+ (date->seconds now) (* num 60)))]
      [(string=? unit "h")
       ;; 小时
       (seconds->date (+ (date->seconds now) (* num 3600)))]
      [(string=? unit "d")
       ;; 天
       (seconds->date (+ (date->seconds now) (* num 86400)))]
      [(string=? unit "w")
       ;; 周
       (seconds->date (+ (date->seconds now) (* num 604800)))]
      [(string=? unit "M")
       ;; 月
       (let* ([new-month (+ (date-month now) num)]
              [year-offset (quotient (- new-month 1) 12)]
              [final-year (+ (date-year now) year-offset)]
              [final-month (+ 1 (remainder (- new-month 1) 12))]
              [max-day (get-month-max-day final-year final-month)]
              [final-day (min (date-day now) max-day)])
         (struct-copy date now
                      (year final-year)
                      (month final-month)
                      (day final-day)))]
      [else now]))) 

;; 解析精确时间格式
(define (parse-exact-time hour minute am-pm day-spec)
  (let ([now (current-date)]
        [hour (string->number hour)]
        [minute (if minute (string->number (substring minute 1)) 0)])
    ;; 处理上午/下午
    (let ([final-hour
           (cond
             [(and am-pm (string=? am-pm "am"))
              (if (= hour 12) 0 hour)]
             [(and am-pm (string=? am-pm "pm"))
              (if (= hour 12) 12 (+ hour 12))]
             [else hour])])
      ;; 计算目标日期
      (let ([target-date
             (cond
               [(or (equal? day-spec "tomorrow") (equal? day-spec "tmw"))
                ;; 明天
                (seconds->date (+ (date->seconds now) 86400))]
               [else
                ;; 今天
                now])])
        (struct-copy date target-date
                     (hour final-hour)
                     (minute minute)
                     (second 0))))))

;; 格式化日期时间为字符串
(define (format-datetime datetime)
  (format "~a-~a-~a ~a:~a" 
          (date-year datetime)
          (~r (date-month datetime) #:min-width 2 #:pad-string "0")
          (~r (date-day datetime) #:min-width 2 #:pad-string "0")
          (~r (date-hour datetime) #:min-width 2 #:pad-string "0")
          (~r (date-minute datetime) #:min-width 2 #:pad-string "0")))

;; 解析日期字符串，支持相对时间和精确时间格式
(define (parse-date-string date-str)
  (let ([trimmed-str (string-trim date-str)])
    (if (equal? trimmed-str "")
        #f
        (cond
          ;; 现有日期时间格式 YYYY-MM-DD HH:MM
          [(and (string-contains? trimmed-str " ")
                (string-contains? trimmed-str ":"))
           trimmed-str]
          ;; 相对时间格式：+Nd, +Nm, +Nh, +Nw, +NM
          [(regexp-match #rx"^\\+([0-9]+)([dmhwM])$" trimmed-str)
           => (lambda (match)
                (format-datetime (parse-relative-time (second match) (third match))))]
          ;; 精确时间格式：@time 或 @time day
          [(regexp-match #rx"^@([0-9]+)(:[0-9]+)?([ap]m)?\\s*(.*)$" trimmed-str)
           => (lambda (match)
                (format-datetime (parse-exact-time (second match) (third match) (fourth match) (string-trim (fifth match)))))]
          ;; 原有 YYYY-MM-DD 格式，添加默认时间 00:00
          [(regexp-match #rx"^[0-9]{4}-[0-9]{2}-[0-9]{2}$" trimmed-str)
           (string-append trimmed-str " 00:00")]
          ;; 其他格式，使用原有函数处理
          [else
           (let ([normalized (normalize-date-string trimmed-str)])
             (if normalized
                 (string-append normalized " 00:00")
                 #f))]))))

;; 验证日期格式是否正确
(define (valid-date? date-str)
  (if (and date-str (string? date-str) (not (equal? date-str "")))
      (let ([normalized (parse-date-string date-str)])
        (if (boolean? normalized) #f #t))
      #t)) ; 空字符串也是有效的

(provide normalize-date-string
         parse-date-string
         get-current-date-string
         format-date-for-display
         is-today?
         valid-date?
         date-diff
         date-string->seconds)