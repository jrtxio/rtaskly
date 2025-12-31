#lang racket

(require racket/date)

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
                         (<= 1 day-num 31)
                         (<= 1900 year-num 9999))
                    (format "~a-~a-~a" 
                            (~r year-num #:min-width 4 #:pad-string "0")
                            (~r month-num #:min-width 2 #:pad-string "0")
                            (~r day-num #:min-width 2 #:pad-string "0"))
                    #f))
              #f))))) ; 如果格式不正确，返回 #f

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

;; 验证日期格式是否正确
(define (valid-date? date-str)
  (if (and date-str (string? date-str) (not (equal? date-str "")))
      (let ([normalized (normalize-date-string date-str)])
        (not (boolean? normalized)))
      #t)) ; 空字符串也是有效的

(provide normalize-date-string
         get-current-date-string
         format-date-for-display
         is-today?
         valid-date?)
