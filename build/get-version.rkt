#lang racket

;; 直接读取info.rkt文件来获取版本号
(require syntax/parse/define)

;; 读取info.rkt文件内容
(define info-content (port->string (open-input-file "../info.rkt")))

;; 解析版本号
(define (extract-version str)
  (define version-regex #px"define version \"([0-9]+(\\.[0-9]+)+)\"")
  (define match (regexp-match version-regex str))
  (if match
      (cadr match)
      "unknown"))

(displayln (extract-version info-content))