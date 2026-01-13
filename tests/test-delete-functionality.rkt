#lang racket

(require rackunit
         rackunit/text-ui
         "test-utils.rkt"
         (prefix-in db: "../src/core/database.rkt")
         (prefix-in lst: "../src/core/list.rkt")
         (prefix-in task: "../src/core/task.rkt")
         "../src/gui/language.rkt")

;; 定义测试套件
(define delete-functionality-tests
  (test-suite
   "删除功能测试"
   
   ;; 测试删除任务功能
   (test-case "删除任务功能" 
     ;; 使用测试工具函数
     (define temp-db-path (setup-db "delete-functionality-test"))
     
     ;; 添加测试列表
     (db:add-list "工作")
     (define lists (lst:get-all-lists))
     (define work-list (first lists))
     (define work-list-id (lst:todo-list-id work-list))
     
     ;; 获取所有任务
     (define initial-tasks (task:get-all-tasks))
     (check-equal? (length initial-tasks) 0)
     
     ;; 测试添加任务
     (task:add-task work-list-id "测试任务1" "2023-01-01")
     (task:add-task work-list-id "测试任务2" "2023-01-02")
     
     ;; 获取所有任务
     (define tasks-after-add (task:get-all-tasks))
     (check-equal? (length tasks-after-add) 2)
     
     ;; 获取第一个任务的ID
     (define first-task (first tasks-after-add))
     (define task-id (task:task-id first-task))
     
     ;; 测试删除任务
     (task:delete-task task-id)
     
     ;; 检查任务是否被删除
     (define tasks-after-delete (task:get-all-tasks))
     (check-equal? (length tasks-after-delete) 1)
     
     ;; 检查剩余任务是否是第二个任务
     (define remaining-task (first tasks-after-delete))
     (check-equal? (task:task-text remaining-task) "测试任务2")
     
     ;; 清理资源
     (teardown-db temp-db-path))
   
   ;; 测试删除按钮的翻译
   (test-case "删除按钮翻译" 
     ;; 测试中文翻译
     (set-language! "zh")
     (check-equal? (translate "删除") "删除")
     
     ;; 测试英文翻译
     (set-language! "en")
     (check-equal? (translate "删除") "Delete")
     
     ;; 恢复默认语言
     (set-language! "zh"))
   
   ;; 测试任务编辑功能
   (test-case "任务编辑功能" 
     ;; 使用测试工具函数
     (define temp-db-path (setup-db "task-edit-test"))
     
     ;; 添加测试列表
     (db:add-list "工作")
     (db:add-list "生活")
     (define lists (lst:get-all-lists))
     (define work-list (first lists))
     (define life-list (second lists))
     (define work-list-id (lst:todo-list-id work-list))
     (define life-list-id (lst:todo-list-id life-list))
     
     ;; 添加测试任务
     (task:add-task work-list-id "测试任务" "2023-01-01")
     
     ;; 获取任务
     (define tasks (task:get-all-tasks))
     (check-equal? (length tasks) 1)
     
     (define task (first tasks))
     (define task-id (task:task-id task))
     
     ;; 测试编辑任务
     (task:edit-task task-id life-list-id "更新后的测试任务" "2023-01-02")
     
     ;; 检查任务是否被更新
     (define updated-tasks (task:get-all-tasks))
     (define updated-task (first updated-tasks))
     (check-equal? (task:task-text updated-task) "更新后的测试任务")
     (check-equal? (task:task-list-id updated-task) life-list-id)
     (check-equal? (task:task-due-date updated-task) "2023-01-02")
     
     ;; 清理资源
     (teardown-db temp-db-path))
  ))

;; 运行测试套件
(run-tests delete-functionality-tests)
