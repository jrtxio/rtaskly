#lang racket

(require racket/file
         racket/path)

;; 定义临时文件前缀
(define temp-file-prefixes '("temp-" "temp-test-"))

;; 清理临时文件
(define (cleanup-temp-files)
  (displayln "\n=== 清理临时文件 ===")
  
  (define test-dir "./")
  (define root-dir "../")
  (define cleaned-count 0)
  
  ;; 处理目录的函数
  (define (process-directory dir)
    (define all-files (find-files (lambda (p) #t) dir #:follow-links? #f))
    (for ([file all-files])
      (define file-name (file-name-from-path file))
      (when file-name
        (define file-name-str (path->string file-name))
        (define is-temp-file (ormap (lambda (prefix) (string-prefix? file-name-str prefix)) temp-file-prefixes))
        (when is-temp-file
          (if (directory-exists? file)
              (begin
                (delete-directory/files file)
                (displayln (format "删除临时目录: ~a" (path->string file)))
              )
              (begin
                (delete-file file)
                (displayln (format "删除临时文件: ~a" (path->string file)))
              )
          )
          (set! cleaned-count (+ cleaned-count 1))
        )
      )
    )
  )
  
  ;; 处理根目录（只清理文件，不递归子目录）
  (define (process-root-directory)
    (define root-files (directory-list root-dir #:build? #t))
    (for ([file root-files])
      (when (file-exists? file)
        (define file-name (file-name-from-path file))
        (when file-name
          (define file-name-str (path->string file-name))
          (define is-temp-file (ormap (lambda (prefix) (string-prefix? file-name-str prefix)) temp-file-prefixes))
          (when is-temp-file
            (delete-file file)
            (displayln (format "删除根目录临时文件: ~a" (path->string file)))
            (set! cleaned-count (+ cleaned-count 1))
          )
        )
      )
    )
  )
  
  ;; 处理测试目录及其子目录
  (process-directory test-dir)
  
  ;; 处理根目录
  (process-root-directory)
  
  (if (> cleaned-count 0)
      (displayln (format "\n已清理 ~a 个临时文件/目录" cleaned-count))
      (displayln "\n没有需要清理的临时文件")
  )
  
  (displayln "=== 清理完成 ===\n")
)

;; 导出函数
(provide cleanup-temp-files)

;; 运行清理（只有当直接运行该文件时才执行）
(cleanup-temp-files)