#lang racket

(require "../../src/utils/date.rkt")

;; 测试函数：测试 parse-date-string 和 format-date-for-display
(define (test-smart-time)
  (displayln "=== 智能时间解析和显示测试 ===")
  
  ;; 测试用例列表
  (define test-cases
    '("+1h"      ; 1小时后
      "+1d"      ; 1天后
      "+2w"      ; 2周后
      "+3M"      ; 3个月后
      "@10am"    ; 今天上午10点
      "@3:30pm"  ; 今天下午3点30分
      "@14:45"   ; 今天下午2点45分
      "@10am tomorrow" ; 明天上午10点
      "2023-12-25" ; 传统日期格式
      ""         ; 空字符串
      "invalid"  ; 无效格式
      ))
  
  (for ([test-case test-cases])
    (displayln (format "\n测试: ~s" test-case))
    (define parsed (parse-date-string test-case))
    (displayln (format "  解析结果: ~s" parsed))
    (displayln (format "  显示格式: ~s" (format-date-for-display parsed))))
  
  ;; 测试 today 检查
  (displayln "\n=== 今天检查测试 ===")
  (define today (get-current-date-string))
  (displayln (format "今天日期: ~s" today))
  (displayln (format "今天带时间: ~s" (string-append today " 10:30")))
  (displayln (format "检查今天: ~a" (is-today? (string-append today " 10:30"))))
  (displayln (format "检查昨天: ~a" (is-today? "2023-01-01")))
  
  ;; 测试日期差计算
  (displayln "\n=== 日期差计算测试 ===")
  (displayln (format "今天到明天: ~a" (date-diff (string-append today " 10:30") today)))
  (displayln (format "明天到今天: ~a" (date-diff today (string-append today " 10:30"))))
  
  (displayln "\n=== 测试完成 ==="))

;; 运行测试
(test-smart-time)