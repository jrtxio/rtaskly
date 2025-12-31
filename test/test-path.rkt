#lang racket

(require rackunit
         rackunit/text-ui
         "../utils/path.rkt"
         racket/path
         racket/file)

;; 定义测试套件
(define path-tests
  (test-suite
   "路径工具测试"
   
   ;; 测试默认应用目录获取
   (test-case "测试默认应用目录获取" 
     (define default-app-dir (get-default-app-dir))
     (check-pred path? default-app-dir)
     (check-equal? (path->string (path-only (build-path default-app-dir "dummy"))) 
                   (path->string (find-system-path 'home-dir)))
     (check-true (directory-exists? default-app-dir)))
   
   ;; 测试默认数据库路径获取
   (test-case "测试默认数据库路径获取" 
     (define default-db-path (get-default-db-path))
     (check-pred path? default-db-path)
     (check-equal? (path->string (path-only default-db-path)) 
                   (path->string (get-default-app-dir)))
     (check-equal? (path->string (file-name-from-path default-db-path)) "tasks.db"))
   
   ;; 测试目录存在性检查和创建
   (test-case "测试目录存在性检查和创建" 
     ;; 创建临时目录路径
     (define temp-dir-path (build-path "./test/temp-test-dir-~a" (current-inexact-milliseconds)))
     
     ;; 确保目录不存在
     (when (directory-exists? temp-dir-path)
       (delete-directory/files temp-dir-path))
     
     ;; 检查目录不存在
     (check-false (directory-exists? temp-dir-path))
     
     ;; 调用 ensure-directory-exists 函数
     (ensure-directory-exists temp-dir-path)
     
     ;; 检查目录是否创建成功
     (check-true (directory-exists? temp-dir-path))
     
     ;; 再次调用 ensure-directory-exists，应该不会出错
     (ensure-directory-exists temp-dir-path)
     (check-true (directory-exists? temp-dir-path))
     
     ;; 清理
     (delete-directory/files temp-dir-path))
   
   ;; 测试 safe-file-exists? 函数
   (test-case "测试 safe-file-exists? 函数" 
     ;; 创建临时文件
     (define temp-file-path (format "./test/temp-test-file-~a.txt" (current-inexact-milliseconds)))
     
     ;; 确保文件不存在
     (when (file-exists? temp-file-path)
       (delete-file temp-file-path))
     
     ;; 检查不存在的文件
     (check-false (safe-file-exists? temp-file-path))
     
     ;; 创建文件
     (with-output-to-file temp-file-path
       (lambda () (display "test content"))
       #:exists 'replace)
     
     ;; 检查文件存在（相对路径）
     (check-true (safe-file-exists? temp-file-path))
     
     ;; 检查文件存在（绝对路径）
     (define abs-path (path->string (build-path (current-directory) temp-file-path)))
     (check-true (safe-file-exists? abs-path))
     
     ;; 清理
     (delete-file temp-file-path))
   
   ;; 测试 get-absolute-path 函数
   (test-case "测试 get-absolute-path 函数" 
     ;; 测试相对路径
     (define rel-path "./test/file.txt")
     (define abs-path (get-absolute-path rel-path))
     (check-pred string? abs-path)
     (check-true (absolute-path? (string->path abs-path)))
     
     ;; 测试绝对路径
     (define actual-abs-path (path->string (build-path (current-directory) "test" "file.txt")))
     (define abs-path-result (get-absolute-path actual-abs-path))
     (check-pred string? abs-path-result)
     (check-equal? abs-path-result actual-abs-path))
   
   ;; 测试 get-filename 函数
   (test-case "测试 get-filename 函数" 
     ;; 测试带路径的文件名
     (define full-path "/home/user/documents/file.txt")
     (define filename (get-filename full-path))
     (check-pred string? filename)
     (check-equal? filename "file.txt")
     
     ;; 测试相对路径
     (define rel-path "./test/file.txt")
     (define filename-rel (get-filename rel-path))
     (check-pred string? filename-rel)
     (check-equal? filename-rel "file.txt")
     
     ;; 测试只有文件名的情况
     (define just-filename "file.txt")
     (define filename-just (get-filename just-filename))
     (check-pred string? filename-just)
     (check-equal? filename-just "file.txt"))
   ))

;; 运行测试套件
(run-tests path-tests)