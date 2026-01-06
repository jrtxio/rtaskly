#lang racket

(require rackunit
         rackunit/text-ui
         "../gui/task-panel.rkt"
         "../utils/date.rkt")

;; 定义测试套件
(define task-input-tests
  (test-suite
   "任务输入功能测试"
   
   ;; 测试任务输入解析功能
   (test-case "任务输入解析功能" 
     ;; 测试相对时间格式
     (define-values (task-text1 due-date1) (parse-task-input "买牛奶 +1d"))
     (check-equal? task-text1 "买牛奶")
     (check-pred string? due-date1) ; 应该返回解析后的日期字符串
     
     ;; 测试精确时间格式
     (define-values (task-text2 due-date2) (parse-task-input "开会 @10am"))
     (check-equal? task-text2 "开会")
     (check-pred string? due-date2)
     
     ;; 测试无时间修饰符
     (define-values (task-text3 due-date3) (parse-task-input "简单任务"))
     (check-equal? task-text3 "简单任务")
     (check-false due-date3)
     
     ;; 测试复杂任务描述
     (define-values (task-text4 due-date4) (parse-task-input "完成项目报告，明天提交 +1d"))
     (check-equal? task-text4 "完成项目报告，明天提交")
     (check-pred string? due-date4)
     
     ;; 测试不同时间单位
     (define-values (task-text5 due-date5) (parse-task-input "测试分钟 +30m"))
     (check-equal? task-text5 "测试分钟")
     (check-pred string? due-date5)
     
     (define-values (task-text6 due-date6) (parse-task-input "测试小时 +2h"))
     (check-equal? task-text6 "测试小时")
     (check-pred string? due-date6)
     
     (define-values (task-text7 due-date7) (parse-task-input "测试周 +1w"))
     (check-equal? task-text7 "测试周")
     (check-pred string? due-date7)
     
     (define-values (task-text8 due-date8) (parse-task-input "测试月 +6M"))
     (check-equal? task-text8 "测试月")
     (check-pred string? due-date8)
     
     ;; 测试精确时间格式的不同写法
     (define-values (task-text9 due-date9) (parse-task-input "午餐 @12:30pm"))
     (check-equal? task-text9 "午餐")
     (check-pred string? due-date9)
     
     (define-values (task-text10 due-date10) (parse-task-input "晚餐 @18:30"))
     (check-equal? task-text10 "晚餐")
     (check-pred string? due-date10))
   
   ;; 测试日期解析功能
   (test-case "日期解析功能" 
     ;; 测试相对时间解析
     (define relative-date1 (parse-date-string "+1d"))
     (check-pred string? relative-date1)
     
     (define relative-date2 (parse-date-string "+2h"))
     (check-pred string? relative-date2)
     
     (define relative-date3 (parse-date-string "+30m"))
     (check-pred string? relative-date3)
     
     (define relative-date4 (parse-date-string "+1w"))
     (check-pred string? relative-date4)
     
     (define relative-date5 (parse-date-string "+6M"))
     (check-pred string? relative-date5)
     
     ;; 测试精确时间解析
     (define exact-date1 (parse-date-string "@10am"))
     (check-pred string? exact-date1)
     
     (define exact-date2 (parse-date-string "@10:30pm"))
     (check-pred string? exact-date2)
     
     (define exact-date3 (parse-date-string "@18:30"))
     (check-pred string? exact-date3)
     
     ;; 测试精确时间带日期
     (define exact-date4 (parse-date-string "@10am tomorrow"))
     (check-pred string? exact-date4)
     
     (define exact-date5 (parse-date-string "@10am tmw"))
     (check-pred string? exact-date5)
     
     (define exact-date6 (parse-date-string "@8pm mon"))
     (check-pred string? exact-date6)
     
     ;; 测试无效日期格式
     (define invalid-date1 (parse-date-string "invalid"))
     (check-false invalid-date1)
     
     (define invalid-date2 (parse-date-string "+invalid"))
     (check-false invalid-date2)
     
     (define invalid-date3 (parse-date-string "@invalid"))
     (check-false invalid-date3))
   )
  )

;; 运行测试套件
(run-tests task-input-tests)