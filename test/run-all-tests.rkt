#lang racket

;; 定义自定义字符串填充函数
(define (string-pad-right s width [pad-char #\space])
  (let* ([len (string-length s)]
         [pad (make-string (max 0 (- width len)) pad-char)])
    (string-append s pad)))

(define (string-pad-left s width [pad-char #\space])
  (let* ([len (string-length s)]
         [pad (make-string (max 0 (- width len)) pad-char)])
    (string-append pad s)))

;; 定义测试文件列表
(define test-files
  '(
    "test-date.rkt"
    "test-database.rkt"
    "test-list.rkt"
    "test-task.rkt"
    "test-path.rkt"
    "test-core-conversion.rkt"
    "test-integration.rkt"
    "test-additional-features.rkt"
    "test-edge-cases.rkt"
    "test-cleanup.rkt"
    "test-sidebar.rkt"
    "test-smart-time.rkt"
    "test-language.rkt"
    ))

;; 运行单个测试文件并返回结果
(define (run-test-file file)
  (displayln (format "运行 ~a..." file))
  (define start-time (current-inexact-milliseconds))
  (define result
    (with-output-to-string
      (lambda ()
        (system (format "racket ~a" file)))))  
  (define end-time (current-inexact-milliseconds))
  (define duration (- end-time start-time))
  
  ;; 简单的结果解析：统计成功、失败和错误的数量
  ;; 我们将使用非常简单的方法：只检查是否包含"FAILURE"或"ERROR"字符串
  (define passed-count
    (if (not (or (string-contains? result "FAILURE") (string-contains? result "ERROR")))
        1 ; 如果没有失败或错误，假设通过1个测试
        0))
  
  (define failed-count
    (if (string-contains? result "FAILURE") 1 0))
  
  (define errors-count
    (if (string-contains? result "ERROR") 1 0))
  
  (list file passed-count failed-count errors-count duration result))

;; 显示测试结果汇总
(define (show-summary results)
  (displayln "\n=== 测试结果汇总 ===")
  (displayln "--------------------------------------------------")
  (displayln "测试文件                 通过  失败  错误  耗时(ms)")
  (displayln "--------------------------------------------------")
  
  ;; 初始化总计数
  (define total-passed 0)
  (define total-failed 0)
  (define total-errors 0)
  (define total-duration 0)
  
  ;; 显示每个测试文件的结果
  (for ([result results])
    (define file (first result))
    (define passed (second result))
    (define failed (third result))
    (define errors (fourth result))
    (define duration (fifth result))
    
    ;; 更新总计数
    (set! total-passed (+ total-passed passed))
    (set! total-failed (+ total-failed failed))
    (set! total-errors (+ total-errors errors))
    (set! total-duration (+ total-duration duration))
    
    ;; 显示单行结果
    (displayln (format "~a~a~a~a~a~a" 
                       (string-pad-right file 24)
                       (string-pad-left (number->string passed) 5)
                       (string-pad-left (number->string failed) 6)
                       (string-pad-left (number->string errors) 6)
                       (string-pad-left (number->string (round duration)) 9)
                       (if (and (= failed 0) (= errors 0)) " ✅" " ❌"))))
  
  (displayln "--------------------------------------------------")
  (displayln (format "总计:                   ~a~a~a~a" 
                     (string-pad-left (number->string total-passed) 5)
                     (string-pad-left (number->string total-failed) 6)
                     (string-pad-left (number->string total-errors) 6)
                     (string-pad-left (number->string (round total-duration)) 9)))
  (displayln "--------------------------------------------------")
  
  ;; 显示最终状态
  (if (and (= total-failed 0) (= total-errors 0))
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
  
  ;; 清理临时文件
  (system "racket cleanup-temp-files.rkt"))

;; 运行主函数
(main)
