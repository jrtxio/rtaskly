#lang racket

(require rackunit
         rackunit/text-ui
         "../core/task.rkt"
         (prefix-in lst: "../core/list.rkt")
         (prefix-in db: "../core/database.rkt")
         "../utils/date.rkt")

;; 定义测试套件
(define task-tests
  (test-suite
   "任务管理测试"
   
   ;; 测试任务管理功能
   (test-case "测试任务管理功能" 
     ;; 创建唯一的临时数据库文件，使用更精确的时间戳
     (define temp-db-path (format "./test/temp-test-~a.db" (current-inexact-milliseconds)))
     
     ;; 确保临时文件不存在
     (when (file-exists? temp-db-path)
       (delete-file temp-db-path))
     
     ;; 连接数据库
     (db:connect-to-database temp-db-path)
     
     ;; 添加测试列表
     (db:add-list "工作")
     (db:add-list "生活")
     (define lists (lst:get-all-lists))
     (define work-list (first lists))
     (define life-list (second lists))
     (define work-list-id (lst:todo-list-id work-list))
     (define life-list-id (lst:todo-list-id life-list))
     
     ;; 测试获取所有任务
     (define initial-tasks (get-all-tasks))
     (check-pred list? initial-tasks)
     (check-equal? (length initial-tasks) 0)
     
     ;; 测试添加任务
     (add-task work-list-id "完成项目报告" "2023-01-01")
     (add-task work-list-id "参加团队会议" #f)
     (add-task life-list-id "购买生活用品" "2023-01-02")
     
     (define tasks-after-add (get-all-tasks))
     (check-equal? (length tasks-after-add) 3)
     
     ;; 测试获取特定列表的任务
     (define work-tasks (get-tasks-by-list work-list-id))
     (check-equal? (length work-tasks) 2)
     
     (define life-tasks (get-tasks-by-list life-list-id))
     (check-equal? (length life-tasks) 1)
     
     ;; 测试获取今天的任务
     (define today-tasks (get-today-tasks))
     (check-pred list? today-tasks)
     
     ;; 测试获取计划任务
     (define planned-tasks (get-planned-tasks))
     (check-equal? (length planned-tasks) 2)
     
     ;; 测试切换任务完成状态
     (define first-task (first tasks-after-add))
     (define task-id-val (task-id first-task))
     (check-false (task-completed? first-task))
     
     (toggle-task-completed task-id-val)
     
     ;; 通过ID查找更新后的任务
     (define all-tasks-after-toggle (get-all-tasks))
     (define updated-task (findf (lambda (t) (= (task-id t) task-id-val)) all-tasks-after-toggle))
     (check-true (task-completed? updated-task))
     
     ;; 测试编辑任务
     (edit-task task-id-val life-list-id "更新后的任务" "2023-01-03")
     
     ;; 通过ID查找编辑后的任务
     (define all-tasks-after-edit (get-all-tasks))
     (define edited-task (findf (lambda (t) (= (task-id t) task-id-val)) all-tasks-after-edit))
     (check-equal? (task-text edited-task) "更新后的任务")
     (check-equal? (task-list-id edited-task) life-list-id)
     (check-equal? (task-due-date edited-task) "2023-01-03")
     
     ;; 测试删除任务
     (delete-task task-id-val)
     (define tasks-after-delete (get-all-tasks))
     (check-equal? (length tasks-after-delete) 2)
     
     ;; 关闭连接并清理
     (db:close-database)
     (when (file-exists? temp-db-path)
       (delete-file temp-db-path)))
   ))

;; 运行测试套件
(run-tests task-tests)