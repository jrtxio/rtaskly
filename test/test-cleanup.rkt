#lang racket

(require rackunit
         rackunit/text-ui
         racket/file
         racket/path
         "../test/cleanup-temp-files.rkt")

;; 定义测试套件
(define cleanup-tests
  (test-suite
   "临时文件清理功能测试"
   
   ;; 测试清理功能
   (test-case "测试临时文件清理功能" 
     ;; 创建临时文件和目录进行测试
     (define test-dir "./test")
     
     ;; 创建临时文件
     (define temp-file1 (build-path test-dir (format "temp-test-~a.txt" (current-inexact-milliseconds))))
     (define temp-file2 (build-path test-dir (format "temp-test-~a.db" (current-inexact-milliseconds))))
     
     ;; 实际创建临时文件
     (with-output-to-file temp-file1 (lambda () (display "test content")) #:exists 'replace)
     (with-output-to-file temp-file2 (lambda () (display "test content")) #:exists 'replace)
     
     ;; 创建临时目录
     (define temp-dir (build-path test-dir (format "temp-test-~a.dir" (current-inexact-milliseconds))))
     (make-directory temp-dir)
     
     ;; 在临时目录中创建文件
     (define temp-file-in-dir (build-path temp-dir "test-file.txt"))
     (with-output-to-file temp-file-in-dir (lambda () (display "test content")) #:exists 'replace)
     
     ;; 创建非临时文件作为对照组
     (define non-temp-file (build-path test-dir (format "normal-test-~a.txt" (current-inexact-milliseconds))))
     (with-output-to-file non-temp-file (lambda () (display "test content")) #:exists 'replace)
     
     ;; 验证文件和目录已创建
     (check-true (file-exists? temp-file1))
     (check-true (file-exists? temp-file2))
     (check-true (directory-exists? temp-dir))
     (check-true (file-exists? temp-file-in-dir))
     (check-true (file-exists? non-temp-file))
     
     ;; 调用清理函数
     (cleanup-temp-files)
     
     ;; 验证临时文件和目录已被清理
     (check-false (file-exists? temp-file1) "临时文件1应被清理")
     (check-false (file-exists? temp-file2) "临时文件2应被清理")
     (check-false (directory-exists? temp-dir) "临时目录应被清理")
     (check-false (file-exists? temp-file-in-dir) "临时目录中的文件应被清理")
     
     ;; 验证非临时文件未被清理
     (check-true (file-exists? non-temp-file) "非临时文件不应被清理")
     
     ;; 清理测试用的非临时文件
     (delete-file non-temp-file)
     )
   
   ;; 测试清理功能的边界情况
   (test-case "测试临时文件清理功能的边界情况" 
     (define test-dir "./test")
     
     ;; 创建多个临时文件
     (define temp-files '())
     (for ([i (in-range 5)])
       (define temp-file (build-path test-dir (format "temp-test-~a-~a.txt" (current-inexact-milliseconds) i)))
       (with-output-to-file temp-file (lambda () (display "test content")) #:exists 'replace)
       (set! temp-files (cons temp-file temp-files)))
     
     ;; 验证所有文件已创建
     (for-each (lambda (file) (check-true (file-exists? file))) temp-files)
     
     ;; 调用清理函数
     (cleanup-temp-files)
     
     ;; 验证所有临时文件已被清理
     (for-each (lambda (file) (check-false (file-exists? file))) temp-files)
     )
   
   ;; 测试空目录情况
   (test-case "测试空目录的清理功能" 
     ;; 确保没有临时文件需要清理
     (cleanup-temp-files) ; 先清理所有现有临时文件
     
     ;; 再次调用清理函数，验证不会报错
     (check-not-exn (lambda () (cleanup-temp-files))) ; 应该不会抛出异常
     )
   
   ;; 测试清理功能的参数处理
   (test-case "测试清理功能的参数处理" 
     ;; 测试临时文件前缀
     (define test-dir "./test")
     
     ;; 创建符合前缀的临时文件
     (define temp-file1 (build-path test-dir "temp-test-123.txt"))
     (with-output-to-file temp-file1 (lambda () (display "test content")) #:exists 'replace)
     
     ;; 创建不符合前缀的文件
     (define temp-file2 (build-path test-dir "temp-not-test-123.txt"))
     (with-output-to-file temp-file2 (lambda () (display "test content")) #:exists 'replace)
     
     ;; 验证文件已创建
     (check-true (file-exists? temp-file1))
     (check-true (file-exists? temp-file2))
     
     ;; 调用清理函数
     (cleanup-temp-files)
     
     ;; 验证符合前缀的文件已被清理
     (check-false (file-exists? temp-file1) "符合前缀的临时文件应被清理")
     
     ;; 验证不符合前缀的文件未被清理
     (check-true (file-exists? temp-file2) "不符合前缀的文件不应被清理")
     
     ;; 清理测试用的不符合前缀的文件
     (delete-file temp-file2)
     )
   ))

;; 运行测试套件
(run-tests cleanup-tests)