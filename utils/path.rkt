#lang racket

(require racket/path
         racket/file)

;; 获取应用程序默认目录
(define (get-default-app-dir)
  (let* ([home-dir (find-system-path 'home-dir)]
         [app-dir (build-path home-dir ".taskly")])
    (unless (directory-exists? app-dir)
      (make-directory* app-dir))
    app-dir))

;; 获取默认数据库文件路径
(define (get-default-db-path)
  (build-path (get-default-app-dir) "tasks.db"))

;; 确保目录存在，如果不存在则创建
(define (ensure-directory-exists dir-path)
  (unless (directory-exists? dir-path)
    (make-directory* dir-path)))

;; 检查文件是否存在
(define (safe-file-exists? path)
  (let ([abs-path (if (relative-path? path) 
                      (build-path (current-directory) path)
                      path)])
    (file-exists? abs-path)))

;; 将相对路径转换为绝对路径
(define (get-absolute-path path)
  (path->string 
   (if (relative-path? path)
       (build-path (current-directory) path)
       path)))

;; 获取文件名（不带路径）
(define (get-filename path)
  (path->string (file-name-from-path path)))

(provide get-default-app-dir
         get-default-db-path
         ensure-directory-exists
         safe-file-exists?
         get-absolute-path
         get-filename)
