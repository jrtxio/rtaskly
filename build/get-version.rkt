#lang racket

;; 直接读取info.rkt文件来获取版本号
(require syntax/parse/define)

;; 获取当前脚本所在目录
(define current-directory (path->string (current-load-relative-directory "")))

;; 构建info.rkt的绝对路径
(define info-file-path (build-path current-directory ".." "info.rkt"))

;; 读取info.rkt文件内容
(define info-content (port->string (open-input-file info-file-path)))

;; 解析版本号
(define (extract-version str)
  (define version-regex #px"define version \"([0-9]+(\\.[0-9]+)+)\"")
  (define match (regexp-match version-regex str))
  (if match
      (cadr match)
      "unknown"))

(displayln (extract-version info-content))