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
(define task-tests
  (test-suite
   "任务管理测试"
   
   ;; 测试任务管理功能
   (test-case "任务管理功能" 
     ;; 使用测试工具函数
     (define temp-db-path (setup-db "task-test"))
     
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
     
     ;; 清理资源
     (teardown-db temp-db-path))
   
   ;; 测试任务视图功能
   (test-case "任务视图功能" 
     ;; 使用测试工具函数
     (define temp-db-path (setup-db "task-view-test"))
     
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
     (check-equal? (length planned-view) 2) ; 包括今天和未来的任务，已完成一个
     
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
     
     ;; 清理资源
     (teardown-db temp-db-path))
   
   ;; 测试任务分组功能
   (test-case "任务分组功能" 
     ;; 使用测试工具函数
     (define temp-db-path (setup-db "task-group-test"))
     
     ;; 获取所有列表（默认应该有2个：工作、生活）
     (define initial-lists (lst:get-all-lists))
     
     ;; 添加一个新的学习列表
     (db:add-list "学习")
     (define lists (lst:get-all-lists))
     (define study-list-id (lst:todo-list-id (last lists)))
     
     ;; 使用默认的工作和生活列表ID
     (define work-list-id (lst:todo-list-id (first lists)))
     (define life-list-id (lst:todo-list-id (second lists)))
     
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
     (check-equal? (length grouped-tasks) 3) ; 应该有3个分组：工作、生活、学习
     
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
     
     ;; 清理资源
     (teardown-db temp-db-path))
   
   ;; 测试任务创建时间
   (test-case "任务创建时间" 
     ;; 使用测试工具函数
     (define temp-db-path (setup-db "task-create-time-test"))
     
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
     
     ;; 清理资源
     (teardown-db temp-db-path))
     
   ;; 测试任务优先级功能
   (test-case "任务优先级功能" 
     ;; 使用测试工具函数
     (define temp-db-path (setup-db "task-priority-test"))
     
     ;; 添加测试列表
     (db:add-list "优先级测试")
     (define list-id (lst:todo-list-id (first (lst:get-all-lists))))
     
     ;; 测试1: 添加不同优先级的任务
     (add-task list-id "低优先级任务" #f 0)
     (add-task list-id "中优先级任务" #f 1)
     (add-task list-id "高优先级任务" #f 2)
     
     ;; 获取所有任务，应该按优先级降序排列
     (define tasks (get-all-tasks))
     (check-equal? (length tasks) 3)
     
     ;; 测试2: 检查任务优先级
     (define task1 (first tasks))
     (define task2 (second tasks))
     (define task3 (third tasks))
     
     ;; 检查任务是否按优先级降序排列
     (check-equal? (task-priority task1) 2) ; 高优先级
     (check-equal? (task-priority task2) 1) ; 中优先级
     (check-equal? (task-priority task3) 0) ; 低优先级
     
     ;; 测试3: 测试优先级默认值
     (add-task list-id "默认优先级任务" #f)
     (define new-tasks (get-all-tasks))
     ;; 查找默认优先级任务
     (define default-priority-task (findf (lambda (t) (equal? (task-text t) "默认优先级任务")) new-tasks))
     (check-equal? (task-priority default-priority-task) 1) ; 默认应该是中优先级
     
     ;; 测试4: 测试编辑任务优先级
     (edit-task (task-id task3) list-id "更新后的低优先级任务" #f 2)
     (define updated-tasks (get-all-tasks))
     ;; 更新后的任务应该现在是高优先级，排在第一位
     (define updated-task (first updated-tasks))
     (check-equal? (task-priority updated-task) 2)
     (check-equal? (task-text updated-task) "更新后的低优先级任务")
     
     ;; 测试5: 测试按优先级排序
     (define sorted-tasks (get-tasks-by-view "list" list-id))
     (check-pred list? sorted-tasks)
     
     ;; 清理资源
     (teardown-db temp-db-path))
     
   ;; 测试数据库升级功能（添加priority列）
   (test-case "数据库升级功能" 
     ;; 使用测试工具函数
     (define temp-db-path (create-temp-db-path "db-upgrade-test"))
     (ensure-file-not-exists temp-db-path)
     
     ;; 1. 创建一个旧版本的数据库（没有priority列）
     (define conn (sqlite3-connect #:database temp-db-path #:mode 'create))
     
     ;; 创建旧版本的表结构（没有priority列）
     (query-exec conn "CREATE TABLE list (
                     list_id INTEGER PRIMARY KEY AUTOINCREMENT,
                     list_name TEXT NOT NULL
                     )")
     
     (query-exec conn "CREATE TABLE task (
                     task_id INTEGER PRIMARY KEY AUTOINCREMENT,
                     list_id INTEGER NOT NULL,
                     task_text TEXT NOT NULL,
                     due_date TEXT NULL,
                     is_completed INTEGER NOT NULL DEFAULT 0,
                     created_at TEXT NOT NULL,
                     FOREIGN KEY (list_id) REFERENCES list(list_id) ON DELETE CASCADE
                     )")
     
     ;; 添加一些测试数据
     (query-exec conn "INSERT INTO list (list_name) VALUES ('旧列表')")
     (query-exec conn "INSERT INTO task (list_id, task_text, due_date, is_completed, created_at) VALUES (1, '旧任务1', NULL, 0, '1234567890')")
     (query-exec conn "INSERT INTO task (list_id, task_text, due_date, is_completed, created_at) VALUES (1, '旧任务2', '2023-01-01', 0, '1234567891')")
     
     ;; 关闭连接
     (disconnect conn)
     
     ;; 2. 使用新版本的代码连接数据库，应该自动升级
     (db:connect-to-database temp-db-path)
     
     ;; 3. 测试是否可以正常添加带有优先级的任务
     (define list-id (lst:todo-list-id (first (lst:get-all-lists))))
     (add-task list-id "新任务带优先级" #f 2)
     
     ;; 4. 测试是否可以获取所有任务（包括旧任务和新任务）
     (define all-tasks (get-all-tasks))
     (check-equal? (length all-tasks) 3)
     
     ;; 5. 测试旧任务是否有默认优先级
     (for ([task all-tasks])
       (define priority (task-priority task))
       (check-pred number? priority)
       (check-true (>= priority 0))
       (check-true (<= priority 2)))
     
     ;; 清理资源
     (db:close-database)
     (cleanup-temp-file temp-db-path))
  ))

;; 运行测试套件
(run-tests task-tests)