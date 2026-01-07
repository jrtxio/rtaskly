#lang racket

(require rackunit
         rackunit/text-ui
         "../src/core/list.rkt"
         "../src/core/task.rkt")

;; 定义测试套件
(define core-conversion-tests
  (test-suite
   "核心模块转换函数测试"
   
   ;; 测试 row->todo-list 函数
   (test-case "测试 row->todo-list 函数" 
     ;; 正常情况：有效的数据库行
     (define valid-row (vector 1 "工作"))
     (define result (row->todo-list valid-row))
     (check-pred todo-list? result)
     (check-equal? (todo-list-id result) 1)
     (check-equal? (todo-list-name result) "工作")
     
     ;; 边界情况：不同ID和名称
     (define another-row (vector 2 "生活"))
     (define another-result (row->todo-list another-row))
     (check-equal? (todo-list-id another-result) 2)
     (check-equal? (todo-list-name another-result) "生活")
     
     ;; 边界情况：空名称
     (define empty-name-row (vector 3 ""))
     (define empty-name-result (row->todo-list empty-name-row))
     (check-equal? (todo-list-name empty-name-result) ""))
   
   ;; 测试 rows->todo-lists 函数
   (test-case "测试 rows->todo-lists 函数" 
     ;; 正常情况：多个有效数据库行
     (define valid-rows (list (vector 1 "工作") (vector 2 "生活") (vector 3 "学习")))
     (define result (rows->todo-lists valid-rows))
     (check-pred list? result)
     (check-equal? (length result) 3)
     (check-pred todo-list? (first result))
     (check-pred todo-list? (second result))
     (check-pred todo-list? (third result))
     (check-equal? (todo-list-name (first result)) "工作")
     (check-equal? (todo-list-name (second result)) "生活")
     (check-equal? (todo-list-name (third result)) "学习")
     
     ;; 边界情况：空列表
     (define empty-result (rows->todo-lists '()))
     (check-pred list? empty-result)
     (check-equal? (length empty-result) 0)
     
     ;; 边界情况：单个元素列表
     (define single-row (list (vector 1 "单个列表")))
     (define single-result (rows->todo-lists single-row))
     (check-pred list? single-result)
     (check-equal? (length single-result) 1)
     (check-equal? (todo-list-name (first single-result)) "单个列表"))
   
   ;; 测试 row->task 函数（简化测试，不依赖数据库函数）
   (test-case "测试 row->task 函数" 
     ;; 正常情况：有效的数据库行
     (define valid-row (vector 1 1 "测试任务" "2023-01-01" 0 "1234567890"))
     
     ;; 直接测试转换逻辑，不依赖 db:get-list-name
     (define result (row->task valid-row))
     (check-pred task? result)
     (check-equal? (task-id result) 1)
     (check-equal? (task-list-id result) 1)
     (check-equal? (task-text result) "测试任务")
     (check-equal? (task-due-date result) "2023-01-01")
     (check-false (task-completed? result))
     (check-equal? (task-created-at result) 1234567890)
     
     ;; 边界情况：已完成任务
     (define completed-row (vector 2 1 "已完成任务" "2023-01-02" 1 "1234567891"))
     (define completed-result (row->task completed-row))
     (check-true (task-completed? completed-result))
     
     ;; 边界情况：无截止日期任务
     (define no-due-date-row (vector 3 1 "无截止日期任务" #f 0 "1234567892"))
     (define no-due-date-result (row->task no-due-date-row))
     (check-false (task-due-date no-due-date-result))
     
     ;; 边界情况：空任务文本
     (define empty-text-row (vector 4 1 "" "2023-01-03" 0 "1234567893"))
     (define empty-text-result (row->task empty-text-row))
     (check-equal? (task-text empty-text-result) ""))
   
   ;; 测试 rows->tasks 函数（简化测试，不依赖数据库函数）
   (test-case "测试 rows->tasks 函数" 
     ;; 正常情况：多个有效数据库行
     (define valid-rows (list 
                         (vector 1 1 "任务1" "2023-01-01" 0 "1234567890")
                         (vector 2 1 "任务2" "2023-01-02" 1 "1234567891")
                         (vector 3 2 "任务3" #f 0 "1234567892")))
     
     (define result (rows->tasks valid-rows))
     (check-pred list? result)
     (check-equal? (length result) 3)
     (check-pred task? (first result))
     (check-pred task? (second result))
     (check-pred task? (third result))
     
     ;; 检查第一个任务
     (check-equal? (task-text (first result)) "任务1")
     (check-false (task-completed? (first result)))
     
     ;; 检查第二个任务（已完成）
     (check-equal? (task-text (second result)) "任务2")
     (check-true (task-completed? (second result)))
     
     ;; 检查第三个任务（无截止日期）
     (check-equal? (task-text (third result)) "任务3")
     (check-false (task-due-date (third result)))
     
     ;; 边界情况：空列表
     (define empty-result (rows->tasks '()))
     (check-pred list? empty-result)
     (check-equal? (length empty-result) 0)
     
     ;; 边界情况：单个元素列表
     (define single-row (list (vector 1 1 "单个任务" "2023-01-01" 0 "1234567890")))
     (define single-result (rows->tasks single-row))
     (check-pred list? single-result)
     (check-equal? (length single-result) 1)
     (check-equal? (task-text (first single-result)) "单个任务"))))

;; 运行测试套件
(run-tests core-conversion-tests)