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

;; 获取配置文件路径
(define (get-config-file-path)
  (build-path (get-default-app-dir) "config.ini"))

;; 读取配置文件
(define (read-config)
  (let ([config-path (get-config-file-path)])
    (if (file-exists? config-path)
        (with-input-from-file config-path
          (lambda ()
            (let loop ([configs '()])
              (let ([line (read-line)])
                (if (eof-object? line)
                    configs
                    (let ([trimmed-line (string-trim line)])
                      (if (and (non-empty-string? trimmed-line)
                               (not (string-prefix? trimmed-line ";")))
                          (let ([parts (string-split trimmed-line "=" #:trim? #t)])
                            (if (= (length parts) 2)
                                (loop (cons (cons (first parts) (second parts)) configs))
                                (loop configs)))
                          (loop configs))))))))
        '())))

;; 保存配置文件
(define (save-config configs)
  (let ([config-path (get-config-file-path)])
    (with-output-to-file config-path
      #:exists 'replace
      (lambda ()
        (for ([config-pair configs])
          (fprintf (current-output-port) "~a=~a\n" (car config-pair) (cdr config-pair)))))))

;; 获取特定配置项
(define (get-config key [default #f])
  (let ([configs (read-config)])
    (let ([value (assoc key configs)])
      (if value
          (cdr value)
          default))))

;; 设置特定配置项
(define (set-config key value)
  (let ([configs (read-config)])
    (let ([new-configs (cons (cons key value) 
                             (filter (lambda (pair) (not (equal? (car pair) key))) configs))])
      (save-config new-configs))))

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
  (let ([path-obj (if (string? path)
                      (string->path path)
                      path)])
    (path->string 
     (if (relative-path? path-obj)
         (build-path (current-directory) path-obj)
         path-obj))))

;; 获取文件名（不带路径）
(define (get-filename path)
  (path->string (file-name-from-path path)))

(provide get-default-app-dir
         get-default-db-path
         get-config-file-path
         read-config
         save-config
         get-config
         set-config
         ensure-directory-exists
         safe-file-exists?
         get-absolute-path
         get-filename)
