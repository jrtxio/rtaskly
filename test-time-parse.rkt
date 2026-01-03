#lang racket

(require "utils/date.rkt")

;; 测试各种时间格式的解析
(define (test-date-parse)
  (define test-cases '(
    ;; 相对时间
    ("+1d" "1天后")
    ("+30m" "30分钟后")
    ("+2h" "2小时后")
    ("+1w" "1周后")
    ("+6M" "6个月后")
    
    ;; 精确时间
    ("@10am" "今天上午10点")
    ("@10:30pm" "今天晚上10点30分")
    ("@22:30" "今天22点30分")
    
    ;; 带日期的精确时间
    ("@10am tomorrow" "明天上午10点")
    ("@10am tmw" "明天上午10点")
    ("@8pm mon" "本周一晚上8点")
    
    ;; 原有格式
    ("2025-08-07" "2025年8月7日")
  ))
  
  (printf "=== 测试时间格式解析 ===\n\n")
  
  (for ([test-case test-cases])
    (define input (first test-case))
    (define description (second test-case))
    
    (define result (parse-date-string input))
    (printf "输入: ~a (~a)\n结果: ~a\n\n" input description result))
  
  (printf "=== 测试完成 ===\n"))

;; 运行测试
(test-date-parse)

;; 主函数，用于单独运行测试
(define (main)
  (test-date-parse))