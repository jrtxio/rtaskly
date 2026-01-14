#lang racket

(require rackunit
         rackunit/text-ui
         db
         racket/gui/base
         "../src/core/task.rkt"
         (prefix-in lst: "../src/core/list.rkt")
         (prefix-in db: "../src/core/database.rkt")
         "../src/utils/date.rkt"
         "../src/utils/font.rkt"
         "test-utils.rkt")

;; 定义测试套件
(define task-render-tests
  (test-suite
   "任务渲染测试"
   
   ;; 测试字体工具函数
   (test-case "字体工具函数测试" 
     ;; 测试 make-app-font 函数
     (define test-font (make-app-font 10))
     (check-pred (lambda (x) (is-a? x font%)) test-font)
     
     ;; 测试不同大小的字体创建
     (define small-font (make-app-font 8))
     (check-pred (lambda (x) (is-a? x font%)) small-font)
     
     (define large-font (make-app-font 16 'bold))
     (check-pred (lambda (x) (is-a? x font%)) large-font))
   
   ;; 测试任务元数据显示
   (test-case "任务元数据测试" 
     ;; 使用测试工具函数
     (define temp-db-path (setup-db "task-metadata-test"))
     
     ;; 添加测试列表
     (db:add-list "工作")
     (define lists (lst:get-all-lists))
     (define work-list (first lists))
     (define work-list-id (lst:todo-list-id work-list))
     
     ;; 获取当前日期
     (define today (get-current-date-string))
     
     ;; 添加带日期的任务
     (add-task work-list-id "带截止日期的任务" today)
     
     ;; 添加无日期的任务
     (add-task work-list-id "无截止日期的任务" #f)
     
     ;; 获取任务
     (define tasks (get-all-tasks))
     (check-equal? (length tasks) 2)
     
     ;; 检查任务结构
     (for ([task tasks])
       (check-pred task? task)
       (check-pred string? (task-text task))
       (check-pred number? (task-id task))
       (check-pred number? (task-list-id task))
       (check-pred (lambda (x) (or (string? x) (false? x))) (task-due-date task))
       (check-pred boolean? (task-completed? task))
       (check-pred string? (task-list-name task)))
     
     ;; 清理资源
     (teardown-db temp-db-path))
   
   ;; 测试长文本任务
   (test-case "长文本任务测试" 
     ;; 使用测试工具函数
     (define temp-db-path (setup-db "task-long-text-test"))
     
     ;; 添加测试列表
     (db:add-list "工作")
     (define lists (lst:get-all-lists))
     (define work-list (first lists))
     (define work-list-id (lst:todo-list-id work-list))
     
     ;; 添加长文本任务
     (define long-text "这是一个非常长的任务描述，用于测试自动换行功能。这个任务描述包含了很多文字，应该能够触发自动换行算法，确保在不同宽度的界面中都能正常显示。")
     (add-task work-list-id long-text #f)
     
     ;; 获取任务
     (define tasks (get-all-tasks))
     (check-equal? (length tasks) 1)
     
     (define long-task (first tasks))
     (check-equal? (task-text long-task) long-text)
     
     ;; 清理资源
     (teardown-db temp-db-path))
   
   ;; 测试任务完成状态
   (test-case "任务完成状态测试" 
     ;; 使用测试工具函数
     (define temp-db-path (setup-db "task-completed-test"))
     
     ;; 添加测试列表
     (db:add-list "工作")
     (define lists (lst:get-all-lists))
     (define work-list (first lists))
     (define work-list-id (lst:todo-list-id work-list))
     
     ;; 添加测试任务
     (add-task work-list-id "测试完成状态的任务" #f)
     
     ;; 获取任务
     (define tasks (get-all-tasks))
     (check-equal? (length tasks) 1)
     
     (define test-task (first tasks))
     (check-false (task-completed? test-task))
     
     ;; 标记任务为完成
     (toggle-task-completed (task-id test-task))
     
     ;; 重新获取任务
     (define updated-tasks (get-all-tasks))
     (define updated-task (first updated-tasks))
     (check-true (task-completed? updated-task))
     
     ;; 标记任务为未完成
     (toggle-task-completed (task-id updated-task))
     
     ;; 重新获取任务
     (define reverted-tasks (get-all-tasks))
     (define reverted-task (first reverted-tasks))
     (check-false (task-completed? reverted-task))
     
     ;; 清理资源
     (teardown-db temp-db-path))
  ))

;; 运行测试套件
(run-tests task-render-tests)
