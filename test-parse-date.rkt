#lang racket

(require "utils/date.rkt")

;; 测试parse-date-string函数
(define test-date "2026-01-04 21:54")
(displayln (format "Testing parse-date-string with ~s:" test-date))

;; 测试正则表达式匹配
(displayln "Testing regex patterns:")
(displayln (format "Multi-space: ~a" (regexp-match #rx"^\\d{4}-\\d{2}-\\d{2}\\s+\\d{2}:\\d{2}$" test-date)))
(displayln (format "Single-space: ~a" (regexp-match #rx"^\\d{4}-\\d{2}-\\d{2}\\s\\d{2}:\\d{2}$" test-date)))

;; 测试parse-date-string
(displayln (format "parse-date-string result: ~a" (parse-date-string test-date)))

;; 测试简化版本
(displayln "\nTesting simplified approach:")
(define (simple-parse date-str)
  (let ([trimmed-str (string-trim date-str)])
    ;; 直接检查是否包含空格和冒号
    (if (and (string-contains? trimmed-str " ")
             (string-contains? trimmed-str ":"))
        trimmed-str
        #f)))
(displayln (format "simple-parse result: ~a" (simple-parse test-date)))