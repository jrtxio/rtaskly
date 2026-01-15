#lang racket

(require rackunit rackunit/text-ui)

;; 自动发现测试文件
(define (find-test-files)
  (define test-dirs '("./core" "./gui" "./utils"))
  (define all-test-files '())
  
  ;; 遍历所有测试目录
  (for ([dir test-dirs])
    (when (directory-exists? dir)
      (define files (directory-list dir #:build? #t))
      (for ([file files])
        (define file-path (path->string file))
        ;; 将反斜杠替换为正斜杠，确保 Racket 可以正确处理路径
        (define normalized-path (string-replace file-path "\\" "/"))
        (define file-name (path->string (file-name-from-path file)))
        ;; 只处理 .rkt 文件，且文件名以 test- 开头
        (when (and (string-suffix? normalized-path ".rkt")
                   (string-prefix? file-name "test-"))
          (set! all-test-files (cons normalized-path all-test-files))))))
  
  ;; 按文件名排序，确保测试运行顺序一致
  (sort all-test-files string<?))

;; 运行单个测试文件并返回结果
(define (run-test-file file)
  (displayln (format "运行 ~a..." file))
  (define start-time (current-inexact-milliseconds))
  
  ;; 使用动态require加载测试文件，捕获错误
  (define-values (passed? output)
    (with-handlers ([exn:fail? (lambda (e)
                                 (values #f (format "加载错误: ~a\n~a" (exn-message e) e)))])
      (values #t
              (with-output-to-string
                (lambda ()
                  (dynamic-require file #f))))))
  
  (define end-time (current-inexact-milliseconds))
  (define duration (- end-time start-time))
  
  (list file passed? duration output))

;; 显示测试结果汇总
(define (show-summary results)
  (displayln "\n=== 测试结果汇总 ===")
  (displayln "--------------------------------------------------")
  (displayln "测试文件                 结果   耗时(ms)")
  (displayln "--------------------------------------------------")
  
  ;; 使用函数式风格统计结果
  (define summary
    (foldl (lambda (result acc)
             (define passed? (second result))
             (define duration (third result))
             (define total-passed (first acc))
             (define total-failed (second acc))
             (define total-duration (third acc))
             
             (list
              (if passed? (+ total-passed 1) total-passed)
              (if passed? total-failed (+ total-failed 1))
              (+ total-duration duration)))
           '(0 0 0)
           results))
  
  (define total-passed (first summary))
  (define total-failed (second summary))
  (define total-duration (third summary))
  
  ;; 显示每个测试文件的结果
  (for ([result results])
    (define file (first result))
    (define passed? (second result))
    (define duration (third result))
    
    ;; 显示单行结果
    (displayln (format "~a~a~a" 
                       (~a file #:min-width 24 #:align 'left)
                       (~a (if passed? "✅ 通过" "❌ 失败") #:min-width 8 #:align 'left)
                       (~a (round duration) #:min-width 10 #:align 'right))))
  
  (displayln "--------------------------------------------------")
  (displayln (format "总计: ~a 通过, ~a 失败, 总耗时: ~a ms" total-passed total-failed (round total-duration)))
  (displayln "--------------------------------------------------")
  
  ;; 显示最终状态
  (if (= total-failed 0)
      (displayln "🎉 所有测试通过！")
      (begin
        (displayln "❌ 部分测试失败或出错！")
        ;; 显示失败的测试详情
        (for ([result results]
              #:when (not (second result)))
          (define file (first result))
          (define output (fourth result))
          (displayln (format "\n=== ~a 失败详情 ===" file))
          (displayln output))))
  
  (displayln "\n=== 测试运行完成 ===\n"))

;; 主函数
(define (main)
  (displayln "\n=== 运行所有测试 ===\n")
  
  ;; 自动发现测试文件
  (define test-files (find-test-files))
  (displayln (format "发现 ~a 个测试文件" (length test-files)))
  
  ;; 运行所有测试
  (define results
    (for/list ([file test-files])
      (run-test-file file)))
  
  ;; 显示汇总结果
  (show-summary results)
  
  ;; 清理临时文件
  (dynamic-require "./cleanup-temp-files.rkt" #f))

;; 运行主函数
(main)