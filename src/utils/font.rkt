#lang racket/gui

;; 字体配置模块，定义应用程序中使用的统一字体
;; 提供一致的字体样式，确保界面视觉统一性

(require racket/system)

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
         create-bold-xlarge-font
         
         ;; 组件专用字体
         create-status-bar-font
         create-button-font
         create-task-input-font
         create-task-text-font
         create-meta-info-font
         
         ;; 应用字体函数
         make-app-font)

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

;; 创建状态条字体
(define (create-status-bar-font)
  (make-app-font 11))

;; 创建按钮字体
(define (create-button-font)
  (make-app-font default-font-size))

;; 创建任务输入框字体
(define (create-task-input-font)
  (make-app-font default-font-size))

;; 创建任务文本字体
(define (create-task-text-font [completed? #f])
  (define size (if (eq? (system-type 'os) 'windows)
                   10.5
                   11))
  (make-app-font size (if completed? 'normal 'bold)))

;; 创建元信息字体
(define (create-meta-info-font)
  (make-app-font 9))

;; 获取当前平台的默认字体
(define (get-platform-default-font)
  (case (system-type 'os)
    [(windows) "Microsoft YaHei"] ;; Windows 平台
    [(macosx) "SF Pro"] ;; macOS 平台
    [(unix) "Ubuntu"] ;; Linux 平台
    [else 'default])) ;; 默认字体

;; 辅助函数:根据平台选择合适的字体
(define (make-app-font size [weight 'normal])
  (define platform-font (get-platform-default-font))
  (if (eq? platform-font 'default)
      (send the-font-list find-or-create-font size 'default 'normal weight)
      (make-object font% size platform-font 'default 'normal weight)))