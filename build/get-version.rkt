#lang racket

;; 直接读取info.rkt文件来获取版本号
(require racket/runtime-path)

;; 定义相对于脚本的运行时路径
(define-runtime-path info-file-path "../info.rkt")

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