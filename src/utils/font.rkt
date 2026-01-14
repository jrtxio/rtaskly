#lang racket/gui

;; 字体配置模块，定义应用程序中使用的统一字体
;; 提供一致的字体样式，确保界面视觉统一性

(provide ;; 字体常量
         default-font
         default-font-size
         small-font-size
         medium-font-size
         large-font-size
         xlarge-font-size
         
         ;; 字体创建函数
         create-default-font
         create-small-font
         create-medium-font
         create-large-font
         create-xlarge-font
         create-bold-font
         create-bold-medium-font
         create-bold-large-font
         create-bold-xlarge-font)

;; 字体大小常量
(define default-font-size 13)
(define small-font-size 11)
(define medium-font-size 14)
(define large-font-size 16)
(define xlarge-font-size 18)

;; 默认字体
(define default-font (send the-font-list find-or-create-font default-font-size 'default 'normal 'normal))

;; 创建默认字体
(define (create-default-font)
  (send the-font-list find-or-create-font default-font-size 'default 'normal 'normal))

;; 创建小字体
(define (create-small-font)
  (send the-font-list find-or-create-font small-font-size 'default 'normal 'normal))

;; 创建中等字体
(define (create-medium-font)
  (send the-font-list find-or-create-font medium-font-size 'default 'normal 'normal))

;; 创建大字体
(define (create-large-font)
  (send the-font-list find-or-create-font large-font-size 'default 'normal 'normal))

;; 创建特大字体
(define (create-xlarge-font)
  (send the-font-list find-or-create-font xlarge-font-size 'default 'normal 'normal))

;; 创建粗体字体
(define (create-bold-font [size default-font-size])
  (send the-font-list find-or-create-font size 'default 'normal 'bold))

;; 创建粗体中等字体
(define (create-bold-medium-font)
  (send the-font-list find-or-create-font medium-font-size 'default 'normal 'bold))

;; 创建粗体大字体
(define (create-bold-large-font)
  (send the-font-list find-or-create-font large-font-size 'default 'normal 'bold))

;; 创建粗体特大字体
(define (create-bold-xlarge-font)
  (send the-font-list find-or-create-font xlarge-font-size 'default 'normal 'bold))