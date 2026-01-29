#lang racket

(require rackunit
         rackunit/text-ui
         racket/file
         ffi/unsafe ffi/unsafe/define
         "../../src/gui/language.rkt"
         "../../src/utils/path.rkt")

;; 语言ID到代码的转换函数
(define (lang-id->code lang-id)
  (cond
    [(= lang-id #x0409) "en"]  ;; 英语(美国)
    [(= lang-id #x0804) "zh"]  ;; 中文(中国)
    [else "en"]))  ;; 未知语言默认英语

;; 定义测试套件
(define system-language-tests
  (test-suite
   "系统语言检测功能测试"

   ;; 测试系统语言API
   (test-case "测试Windows语言API调用"
              (if (eq? (system-type) 'windows)
                  (let ()
                    (define kernel32 (ffi-lib "kernel32"))
                    (define GetUserDefaultUILanguage (get-ffi-obj "GetUserDefaultUILanguage" kernel32 (_fun -> _uint)))

                    (check-pred exact-positive-integer? (GetUserDefaultUILanguage))
                    (displayln (format "系统UI语言ID: ~a (#x~x)" (GetUserDefaultUILanguage) (GetUserDefaultUILanguage))))
                  (displayln "非Windows系统，跳过Windows API测试")))

   ;; 测试语言ID转换
   (test-case "测试语言ID到代码的转换"
              (check-equal? (lang-id->code #x0409) "en")  ;; 英语(美国)
              (check-equal? (lang-id->code #x0804) "zh")  ;; 中文(中国)
              (check-equal? (lang-id->code #x0000) "en"))  ;; 未知语言默认英语

   ;; 测试首次启动（无配置文件）
   (test-case "测试首次启动使用系统语言"
              ;; 保存原始语言设置
              (define original-lang (current-language))

              ;; 删除语言配置项
              (set-config "language" "")

              ;; 加载语言设置（应该使用系统语言）
              (load-language-setting)

              ;; 获取系统语言
              (if (eq? (system-type) 'windows)
                  (let ()
                    (define kernel32 (ffi-lib "kernel32"))
                    (define GetUserDefaultUILanguage (get-ffi-obj "GetUserDefaultUILanguage" kernel32 (_fun -> _uint)))
                    (define expected-lang (lang-id->code (GetUserDefaultUILanguage)))
                    (check-equal? (current-language) expected-lang))
                  (check-pred string? (current-language)))

              ;; 恢复原始语言
              (set-language! original-lang)
              (save-language-setting))

   ;; 测试已存在配置文件的情况
   (test-case "测试有配置文件时使用保存的语言"
              ;; 保存原始语言设置
              (define original-lang (current-language))

              ;; 创建测试配置（设置为中文）
              (set-config "language" "zh")

              ;; 加载语言设置
              (set-language! "en")  ;; 先切换到英文
              (load-language-setting)

              ;; 检查语言是否为配置中保存的中文
              (check-equal? (current-language) "zh")

              ;; 恢复原始语言
              (set-language! original-lang)
              (save-language-setting))

   ;; 测试配置项不存在的情况
   (test-case "测试配置项不存在时使用系统语言"
              ;; 保存原始语言设置
              (define original-lang (current-language))

              ;; 删除语言配置项
              (set-config "language" "")

              ;; 加载语言设置
              (set-language! "en")  ;; 先切换到英文
              (load-language-setting)

              ;; 检查语言是否为默认值（配置项不存在时应该使用系统语言）
              (if (eq? (system-type) 'windows)
                  (let ()
                    (define kernel32 (ffi-lib "kernel32"))
                    (define GetUserDefaultUILanguage (get-ffi-obj "GetUserDefaultUILanguage" kernel32 (_fun -> _uint)))
                    (define expected-lang (lang-id->code (GetUserDefaultUILanguage)))
                    (check-equal? (current-language) expected-lang))
                  (check-pred string? (current-language)))

              ;; 恢复原始语言
              (set-language! original-lang)
              (save-language-setting))
   ))

;; 运行测试
(displayln "开始运行系统语言检测功能测试...")
(run-tests system-language-tests)
