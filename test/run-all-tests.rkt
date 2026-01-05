#lang racket

;; 定义测试文件列表
(define test-files
  '("test-date.rkt" "test-database.rkt" "test-list.rkt" "test-task.rkt" "test-path.rkt" 
    "test-core-conversion.rkt" "test-integration.rkt" "test-additional-features.rkt" 
    "test-edge-cases.rkt" "test-cleanup.rkt" "test-sidebar.rkt" "test-smart-time.rkt" 
    "test-language.rkt" "test-null-date-handling.rkt" "test-fix-verification.rkt" 
    "test-db-suffix-automatic-addition.rkt" "test-long-task-text.rkt"))

;; 运行单个测试文件并返回结果
(define (run-test-file file)
  (displayln (format "运行 ~a..." file))
  (define start-time (current-inexact-milliseconds))
  (define result
    (with-output-to-string
      (lambda ()
        (system (format "racket ./test/~a" file)))))  ; 修复路径
  (define end-time (current-inexact-milliseconds))
  (define duration (- end-time start-time))
  
  ;; 改进结果解析
  (define passed? (not (or (string-contains? result "FAILURE") (string-contains? result "ERROR"))))
  (list file passed? duration result))

;; 显示测试结果汇总
(define (show-summary results)
  (displayln "\n=== 测试结果汇总 ===")
  (displayln "--------------------------------------------------")
  (displayln "测试文件                 结果   耗时(ms)")
  (displayln "--------------------------------------------------")
  
  ;; 初始化总计数
  (define total-passed 0)
  (define total-failed 0)
  (define total-duration 0)
  
  ;; 显示每个测试文件的结果
  (for ([result results])
    (define file (first result))
    (define passed? (second result))
    (define duration (third result))
    
    ;; 更新总计数
    (if passed?
        (set! total-passed (+ total-passed 1))
        (set! total-failed (+ total-failed 1)))
    (set! total-duration (+ total-duration duration))
    
    ;; 显示单行结果
    (displayln (format "~a~a~a" 
                       (~a file #:min-width 24 #:align 'left)  ; 使用 racket 的格式化功能
                       (~a (if passed? "✅ 通过" "❌ 失败") #:min-width 8 #:align 'left)
                       (~a (round duration) #:min-width 10 #:align 'right))))
  
  (displayln "--------------------------------------------------")
  (displayln (format "总计: ~a 通过, ~a 失败, 总耗时: ~a ms" total-passed total-failed (round total-duration)))
  (displayln "--------------------------------------------------")
  
  ;; 显示最终状态
  (if (= total-failed 0)
      (displayln "🎉 所有测试通过！")
      (displayln "❌ 部分测试失败或出错！"))
  (displayln "\n=== 测试运行完成 ===\n"))

;; 主函数
(define (main)
  (displayln "\n=== 运行所有测试 ===\n")
  
  ;; 运行所有测试
  (define results
    (for/list ([file test-files])
      (run-test-file file)))
  
  ;; 显示汇总结果
  (show-summary results)
  
  ;; 清理临时文件（修复路径）
  (system "racket ./test/cleanup-temp-files.rkt"))

;; 运行主函数
(main)