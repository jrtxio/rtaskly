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
     (check-equal? (normalize-date-string "2023-01-01") "2023-01-01")
     (check-equal? (normalize-date-string "2023-1-1") "2023-01-01")
     (check-equal? (normalize-date-string " 2023-01-01 ") "2023-01-01")
     (check-false (normalize-date-string "2023/01/01"))
     (check-false (normalize-date-string "2023-13-01"))
     ;; 注意：当前实现不检查具体月份的天数
     (check-equal? (normalize-date-string "2023-02-30") "2023-02-30")
     (check-false (normalize-date-string ""))
     (check-false (normalize-date-string "invalid-date")))
   
   ;; 测试 get-current-date-string 函数
   (test-case "测试当前日期字符串生成" 
     (define date-str (get-current-date-string))
     (check-pred string? date-str)
     (check-equal? (length (string-split date-str "-")) 3)
     ;; 检查格式是否为 YYYY-MM-DD
     (check-regexp-match #px"^\\d{4}-\\d{2}-\\d{2}$" date-str))
   
   ;; 测试 format-date-for-display 函数
   (test-case "测试日期显示格式化" 
     (check-equal? (format-date-for-display "2023-01-01") "1月1日")
     (check-equal? (format-date-for-display "2023-12-31") "12月31日")
     (check-equal? (format-date-for-display "") "")
     (check-equal? (format-date-for-display #f) "")
     (check-equal? (format-date-for-display "invalid-date") "invalid-date"))
   
   ;; 测试 is-today? 函数
   (test-case "测试日期是否为今天" 
     (define today (get-current-date-string))
     (check-true (is-today? today))
     (check-false (is-today? "2023-01-01"))
     (check-false (is-today? ""))
     (check-false (is-today? #f)))
   
   ;; 测试 valid-date? 函数
   (test-case "测试日期格式有效性" 
     (check-true (valid-date? "2023-01-01"))
     (check-true (valid-date? "2023-1-1"))
     (check-true (valid-date? ""))
     (check-true (valid-date? #f))
     (check-false (valid-date? "2023/01/01"))
     (check-false (valid-date? "2023-13-01"))
     ;; 注意：当前实现不检查具体月份的天数
     (check-true (valid-date? "2023-02-30"))
     (check-false (valid-date? "invalid-date")))
   ))

;; 运行测试套件
(run-tests date-tests)