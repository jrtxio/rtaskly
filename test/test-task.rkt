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
   
   ;; 测试任务视图功能
   (test-case "测试任务视图功能" 
     ;; 创建唯一的临时数据库文件
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
     
     ;; 获取当前日期
     (define today (get-current-date-string))
     
     ;; 添加不同类型的任务
     (add-task work-list-id "今天的工作任务" today)
     (add-task life-list-id "今天的生活任务" today)
     (add-task work-list-id "未来的工作任务" "2099-12-31")
     (add-task life-list-id "无截止日期的任务" #f)
     
     ;; 完成一个任务
     (define tasks-after-add (get-all-tasks))
     (define first-task (first tasks-after-add))
     (toggle-task-completed (task-id first-task))
     
     ;; 测试获取所有未完成任务
     (define all-incomplete (get-all-incomplete-tasks))
     (check-pred list? all-incomplete)
     (check-equal? (length all-incomplete) 3)
     
     ;; 测试获取所有已完成任务
     (define all-completed (get-all-completed-tasks))
     (check-pred list? all-completed)
     (check-equal? (length all-completed) 1)
     
     ;; 测试 get-tasks-by-view 函数
     ;; 测试 today 视图
     (define today-view (get-tasks-by-view "today"))
     (check-pred list? today-view)
     
     ;; 测试 planned 视图
     (define planned-view (get-tasks-by-view "planned"))
     (check-pred list? planned-view)
     (check-equal? (length planned-view) 3) ; 包括今天和未来的任务
     
     ;; 测试 all 视图（未完成任务）
     (define all-view (get-tasks-by-view "all"))
     (check-pred list? all-view)
     (check-equal? (length all-view) 3) ; 所有未完成任务
     
     ;; 测试 completed 视图
     (define completed-view (get-tasks-by-view "completed"))
     (check-pred list? completed-view)
     (check-equal? (length completed-view) 1) ; 所有已完成任务
     
     ;; 测试 list 视图
     (define work-list-view (get-tasks-by-view "list" work-list-id))
     (check-pred list? work-list-view)
     
     (define life-list-view (get-tasks-by-view "list" life-list-id))
     (check-pred list? life-list-view)
     
     ;; 测试无效视图类型
     (define invalid-view (get-tasks-by-view "invalid"))
     (check-pred list? invalid-view)
     (check-equal? (length invalid-view) 0)
     
     ;; 关闭连接并清理
     (db:close-database)
     (when (file-exists? temp-db-path)
       (delete-file temp-db-path)))
   
   ;; 测试任务分组功能
   (test-case "测试任务分组功能" 
     ;; 创建唯一的临时数据库文件
     (define temp-db-path (format "./test/temp-test-~a.db" (current-inexact-milliseconds)))
     
     ;; 确保临时文件不存在
     (when (file-exists? temp-db-path)
       (delete-file temp-db-path))
     
     ;; 连接数据库
     (db:connect-to-database temp-db-path)
     
     ;; 添加测试列表
     (db:add-list "工作")
     (db:add-list "生活")
     (db:add-list "学习")
     (define lists (lst:get-all-lists))
     (define work-list-id (lst:todo-list-id (first lists)))
     (define life-list-id (lst:todo-list-id (second lists)))
     (define study-list-id (lst:todo-list-id (third lists)))
     
     ;; 添加测试任务
     (add-task work-list-id "完成项目报告" "2023-01-01")
     (add-task work-list-id "参加团队会议" #f)
     (add-task life-list-id "购买生活用品" "2023-01-02")
     (add-task study-list-id "学习Racket编程" "2023-01-03")
     (add-task study-list-id "准备考试" #f)
     
     ;; 获取所有任务
     (define all-tasks (get-all-tasks))
     (check-equal? (length all-tasks) 5)
     
     ;; 测试分组功能
     (define grouped-tasks (group-tasks-by-list all-tasks))
     (check-pred list? grouped-tasks)
     (check-equal? (length grouped-tasks) 3) ; 应该有3个分组
     
     ;; 检查每个分组是否包含正确的任务数量
     (for ([group grouped-tasks])
       (define list-name (car group))
       (define tasks (cdr group))
       (check-pred list? tasks)
       
       ;; 检查分组名称是否正确
       (check-true (or (equal? list-name "工作")
                       (equal? list-name "生活")
                       (equal? list-name "学习")))
       
       ;; 检查每个分组的任务数量
       (cond
         [(equal? list-name "工作") (check-equal? (length tasks) 2)]
         [(equal? list-name "生活") (check-equal? (length tasks) 1)]
         [(equal? list-name "学习") (check-equal? (length tasks) 2)]))
     
     ;; 测试空任务列表的分组
     (define empty-grouped (group-tasks-by-list '()))
     (check-pred list? empty-grouped)
     (check-equal? (length empty-grouped) 0)
     
     ;; 关闭连接并清理
     (db:close-database)
     (when (file-exists? temp-db-path)
       (delete-file temp-db-path)))
   
   ;; 测试任务创建时间
   (test-case "测试任务创建时间" 
     ;; 创建唯一的临时数据库文件
     (define temp-db-path (format "./test/temp-test-~a.db" (current-inexact-milliseconds)))
     
     ;; 确保临时文件不存在
     (when (file-exists? temp-db-path)
       (delete-file temp-db-path))
     
     ;; 连接数据库
     (db:connect-to-database temp-db-path)
     
     ;; 添加测试列表
     (db:add-list "测试列表")
     (define list-id (lst:todo-list-id (first (lst:get-all-lists))))
     
     ;; 记录当前时间
     (define before-create (current-seconds))
     
     ;; 添加测试任务
     (add-task list-id "测试任务" #f)
     
     ;; 获取任务
     (define tasks (get-all-tasks))
     (check-equal? (length tasks) 1)
     
     (define task (first tasks))
     (define created-at (task-created-at task))
     
     ;; 检查创建时间是否为数字
     (check-pred number? created-at)
     
     ;; 检查创建时间是否在合理范围内
     (check-true (<= before-create created-at (current-seconds)))
     
     ;; 关闭连接并清理
     (db:close-database)
     (when (file-exists? temp-db-path)
       (delete-file temp-db-path)))
   ))

;; 运行测试套件
(run-tests task-tests)