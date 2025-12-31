#lang racket

(require racket/file
         racket/path)

;; 定义临时文件前缀
(define temp-file-prefixes
  '("temp-test-"))

;; 清理临时文件
(define (cleanup-temp-files)
  (displayln "\n=== 清理临时文件 ===")
  
  (define test-dir "./test")
  (define cleaned-count 0)
  
  ;; 查找测试目录下的所有文件和目录
  (define all-files (find-files (lambda (p) #t) test-dir))
  
  ;; 遍历所有文件和目录，删除匹配的临时文件
  (for ([file all-files])
    (define file-name (path->string (file-name-from-path file)))
    (define is-temp-file
      (ormap (lambda (prefix) (string-prefix? file-name prefix)) temp-file-prefixes))
    
    (when is-temp-file
      (if (directory-exists? file)
          (begin
            (delete-directory/files file)
            (displayln (format "删除临时目录: ~a" (path->string file))))
          (begin
            (delete-file file)
            (displayln (format "删除临时文件: ~a" (path->string file)))))  
      (set! cleaned-count (+ cleaned-count 1))))
  
  (if (> cleaned-count 0)
      (displayln (format "\n已清理 ~a 个临时文件/目录" cleaned-count))
      (displayln "\n没有需要清理的临时文件"))
  
  (displayln "=== 清理完成 ===\n"))

;; 运行清理
(cleanup-temp-files)