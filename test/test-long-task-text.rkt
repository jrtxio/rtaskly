#lang racket

(require rackunit
         rackunit/text-ui
         db
         "../core/task.rkt"
         (prefix-in lst: "../core/list.rkt")
         (prefix-in db: "../core/database.rkt")
         "../utils/date.rkt"
         "utils/test-utils.rkt")

;; 定义测试套件
(define long-task-text-tests
  (test-suite
   "长任务文本处理测试"
   
   ;; 测试长任务文本处理功能
   (test-case "基本长文本测试" 
     ;; 使用测试工具函数
     (define temp-db-path (setup-db "long-task-test-basic"))
     
     ;; 添加测试列表
     (db:add-list "测试列表")
     (define list-id (lst:todo-list-id (first (lst:get-all-lists))))
     
     ;; 生成中等长度的文本（约100个字符）
     (define medium-text (string-join (make-list 20 "这是一个测试文本") " "))
     
     ;; 测试添加中等长度任务
     (add-task list-id medium-text #f)
     
     ;; 获取任务
     (define tasks (get-all-tasks))
     (check-equal? (length tasks) 1)
     
     (define task (first tasks))
     (check-equal? (task-text task) medium-text)
     
     ;; 清理资源
     (teardown-db temp-db-path))
   
   ;; 测试超长长文本处理
   (test-case "超长长文本测试" 
     ;; 使用测试工具函数
     (define temp-db-path (setup-db "long-task-test-super"))
     
     ;; 添加测试列表
     (db:add-list "测试列表")
     (define list-id (lst:todo-list-id (first (lst:get-all-lists))))
     
     ;; 生成超长度的文本（约500个字符）
     (define super-long-text (string-join (make-list 100 "这是一个超长测试文本") " "))
     
     ;; 测试添加超长任务
     (add-task list-id super-long-text #f)
     
     ;; 获取任务
     (define tasks (get-all-tasks))
     (check-equal? (length tasks) 1)
     
     (define task (first tasks))
     (check-equal? (task-text task) super-long-text)
     
     ;; 清理资源
     (teardown-db temp-db-path))
   
   ;; 测试极端长文本处理
   (test-case "极端长文本测试" 
     ;; 使用测试工具函数
     (define temp-db-path (setup-db "long-task-test-extreme"))
     
     ;; 添加测试列表
     (db:add-list "测试列表")
     (define list-id (lst:todo-list-id (first (lst:get-all-lists))))
     
     ;; 生成极端长度的文本（约2000个字符）
     (define extreme-long-text (string-join (make-list 400 "这是一个极端超长测试文本") " "))
     
     ;; 测试添加极端长任务
     (add-task list-id extreme-long-text #f)
     
     ;; 获取任务
     (define tasks (get-all-tasks))
     (check-equal? (length tasks) 1)
     
     (define task (first tasks))
     (check-equal? (task-text task) extreme-long-text)
     
     ;; 清理资源
     (teardown-db temp-db-path))
   
   ;; 测试特殊字符长文本处理
   (test-case "特殊字符长文本测试" 
     ;; 使用测试工具函数
     (define temp-db-path (setup-db "long-task-test-special"))
     
     ;; 添加测试列表
     (db:add-list "测试列表")
     (define list-id (lst:todo-list-id (first (lst:get-all-lists))))
     
     ;; 生成包含特殊字符的长文本
     (define special-chars "!@#$%^&*()_+-=[]{}|;:,.<>?/~`\n\t\r")
     (define special-long-text (string-join (make-list 20 (string-append "特殊字符测试: " special-chars)) " "))
     
     ;; 测试添加包含特殊字符的长任务
     (add-task list-id special-long-text #f)
     
     ;; 获取任务
     (define tasks (get-all-tasks))
     (check-equal? (length tasks) 1)
     
     (define task (first tasks))
     (check-equal? (task-text task) special-long-text)
     
     ;; 清理资源
     (teardown-db temp-db-path))
   
   ;; 测试空文本处理
   (test-case "空文本测试" 
     ;; 使用测试工具函数
     (define temp-db-path (setup-db "long-task-test-empty"))
     
     ;; 添加测试列表
     (db:add-list "测试列表")
     (define list-id (lst:todo-list-id (first (lst:get-all-lists))))
     
     ;; 测试添加空文本任务
     (add-task list-id "" #f)
     
     ;; 获取任务
     (define tasks (get-all-tasks))
     (check-equal? (length tasks) 1)
     
     (define task (first tasks))
     (check-equal? (task-text task) "")
     
     ;; 清理资源
     (teardown-db temp-db-path))
   
   ;; 测试多个长文本任务
   (test-case "多个长文本任务测试" 
     ;; 使用测试工具函数
     (define temp-db-path (setup-db "long-task-test-multiple"))
     
     ;; 添加测试列表
     (db:add-list "测试列表")
     (define list-id (lst:todo-list-id (first (lst:get-all-lists))))
     
     ;; 生成不同长度的文本
     (define texts (list
                    (string-join (make-list 10 "短文本") " ")
                    (string-join (make-list 50 "中等长度文本") " ")
                    (string-join (make-list 100 "长文本") " ")))
     
     ;; 测试添加多个不同长度的任务
     (for ([text texts])
       (add-task list-id text #f))
     
     ;; 获取任务
     (define tasks (get-all-tasks))
     (check-equal? (length tasks) 3)
     
     ;; 验证每个任务的文本
     (for ([i (in-range 3)])
       (define task (list-ref tasks i))
       (check-equal? (task-text task) (list-ref texts i))) ; 任务是按创建时间正序返回的
     
     ;; 清理资源
     (teardown-db temp-db-path))
  ))

;; 运行测试套件
(run-tests long-task-text-tests)