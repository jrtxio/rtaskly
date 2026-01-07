#lang racket

(require rackunit
         rackunit/text-ui
         "../src/core/list.rkt"
         "../src/core/task.rkt"
         (prefix-in db: "../src/core/database.rkt")
         "../src/utils/date.rkt")

;; 定义测试套件
(define integration-tests
  (test-suite
   "综合功能测试"
   
   ;; 测试列表和任务的综合操作
   (test-case "测试列表和任务的综合操作" 
     ;; 创建唯一的临时数据库文件
     (define temp-db-path (format "./test/temp-test-~a.db" (current-inexact-milliseconds)))
     
     ;; 确保临时文件不存在
     (when (file-exists? temp-db-path)
       (delete-file temp-db-path))
     
     ;; 连接数据库
     (db:connect-to-database temp-db-path)
     
     ;; 1. 创建列表
     (define lists-before (get-all-lists))
     (check-equal? (length lists-before) 2)
     
     (add-list "综合测试列表")
     (define lists-after-add (get-all-lists))
     (check-equal? (length lists-after-add) 3)
     
     (define test-list (last lists-after-add))
     (define test-list-id (todo-list-id test-list))
     
     ;; 2. 在列表中添加任务
     (define tasks-before-add (get-all-tasks))
     (check-equal? (length tasks-before-add) 0)
     
     ;; 添加不同类型的任务
     (add-task test-list-id "任务1-有截止日期" "2023-01-01")
     (add-task test-list-id "任务2-无截止日期" #f)
     (add-task test-list-id "任务3-今天的任务" (get-current-date-string))
     
     (define tasks-after-add (get-all-tasks))
     (check-equal? (length tasks-after-add) 3)
     
     ;; 3. 测试按列表获取任务
     (define list-tasks (get-tasks-by-list test-list-id))
     (check-equal? (length list-tasks) 3)
     
     ;; 4. 测试任务状态转换
     ;; 完成一个任务
     (define task-to-complete (first list-tasks))
     (toggle-task-completed (task-id task-to-complete))
     
     ;; 检查任务状态
     (define updated-tasks (get-tasks-by-list test-list-id))
     ;; 由于 get-tasks-by-list 现在只返回未完成的任务，完成的任务不会出现在列表中
     (check-equal? (length updated-tasks) 2) ; 应该只剩下2个未完成的任务
     
     ;; 检查完成的任务是否在已完成任务列表中
     (define completed-tasks (get-all-completed-tasks))
     (define completed-task (findf (lambda (t) (= (task-id t) (task-id task-to-complete))) completed-tasks))
     (check-true (task-completed? completed-task))
     
     ;; 5. 测试更新任务
     (edit-task (task-id completed-task) test-list-id "更新后的任务" "2023-01-02")
     (define updated-task (findf (lambda (t) (= (task-id t) (task-id completed-task))) (get-all-tasks)))
     (check-equal? (task-text updated-task) "更新后的任务")
     (check-equal? (task-due-date updated-task) "2023-01-02")
     
     ;; 6. 测试删除任务
     (delete-task (task-id updated-task))
     (define tasks-after-delete (get-all-tasks))
     (check-equal? (length tasks-after-delete) 2)
     
     ;; 7. 测试删除列表（级联删除任务）
     (delete-list test-list-id)
     (define tasks-after-list-delete (get-all-tasks))
     (check-equal? (length tasks-after-list-delete) 0)
     
     ;; 关闭连接并清理
     (db:close-database)
     (when (file-exists? temp-db-path)
       (delete-file temp-db-path)))
   
   ;; 测试不同视图下的任务获取
   (test-case "测试不同视图下的任务获取" 
     ;; 创建唯一的临时数据库文件
     (define temp-db-path (format "./test/temp-test-~a.db" (current-inexact-milliseconds)))
     
     ;; 确保临时文件不存在
     (when (file-exists? temp-db-path)
       (delete-file temp-db-path))
     
     ;; 连接数据库
     (db:connect-to-database temp-db-path)
     
     ;; 添加测试列表
     (add-list "视图测试列表1")
     (add-list "视图测试列表2")
     (define lists (get-all-lists))
     (define list1-id (todo-list-id (first lists)))
     (define list2-id (todo-list-id (second lists)))
     
     ;; 获取当前日期
     (define today (get-current-date-string))
     
     ;; 添加不同类型的任务到不同列表
     ;; 列表1的任务
     (add-task list1-id "列表1-今天的任务" today)
     (add-task list1-id "列表1-未来的任务" "2099-12-31")
     (add-task list1-id "列表1-无截止日期" #f)
     
     ;; 列表2的任务
     (add-task list2-id "列表2-今天的任务" today)
     (add-task list2-id "列表2-未来的任务" "2099-12-31")
     
     ;; 完成一些任务
     (define all-tasks (get-all-tasks))
     (toggle-task-completed (task-id (first all-tasks))) ; 完成第一个任务
     (toggle-task-completed (task-id (third all-tasks))) ; 完成第三个任务
     
     ;; 测试不同视图
     ;; 1. 测试 all 视图（所有未完成任务）
     (define all-view (get-tasks-by-view "all"))
     (check-pred list? all-view)
     (check-equal? (length all-view) 3) ; 5个任务 - 2个已完成 = 3个未完成
     
     ;; 2. 测试 completed 视图（所有已完成任务）
     (define completed-view (get-tasks-by-view "completed"))
     (check-pred list? completed-view)
     (check-equal? (length completed-view) 2) ; 2个已完成任务
     
     ;; 3. 测试 planned 视图（有截止日期且未完成）
     (define planned-view (get-tasks-by-view "planned"))
     (check-pred list? planned-view)
     (check-equal? (length planned-view) 2) ; 4个有截止日期的任务 - 1个已完成 = 3个未完成
     
     ;; 4. 测试 list 视图
     (define list1-view (get-tasks-by-view "list" list1-id))
     (check-pred list? list1-view)
     (check-equal? (length list1-view) 1) ; 列表1有3个任务，其中2个已完成，所以返回1个
     
     (define list2-view (get-tasks-by-view "list" list2-id))
     (check-pred list? list2-view)
     (check-equal? (length list2-view) 2) ; 列表2有2个任务，都未完成
     
     ;; 5. 测试 today 视图
     (define today-view (get-tasks-by-view "today"))
     (check-pred list? today-view)
     
     ;; 关闭连接并清理
     (db:close-database)
     (when (file-exists? temp-db-path)
       (delete-file temp-db-path)))
   
   ;; 测试任务状态转换流程
   (test-case "测试任务状态转换流程" 
     ;; 创建唯一的临时数据库文件
     (define temp-db-path (format "./test/temp-test-~a.db" (current-inexact-milliseconds)))
     
     ;; 确保临时文件不存在
     (when (file-exists? temp-db-path)
       (delete-file temp-db-path))
     
     ;; 连接数据库
     (db:connect-to-database temp-db-path)
     
     ;; 添加测试列表
     (add-list "状态转换测试列表")
     (define list-id (todo-list-id (first (get-all-lists))))
     
     ;; 添加测试任务
     (add-task list-id "状态转换测试任务" "2023-01-01")
     
     ;; 1. 初始状态：未完成
     (define initial-tasks (get-all-tasks))
     (check-equal? (length initial-tasks) 1)
     (define task (first initial-tasks))
     (check-false (task-completed? task))
     
     ;; 检查未完成任务列表
     (define initial-incomplete (get-all-incomplete-tasks))
     (check-equal? (length initial-incomplete) 1)
     
     ;; 检查已完成任务列表
     (define initial-completed (get-all-completed-tasks))
     (check-equal? (length initial-completed) 0)
     
     ;; 2. 标记为完成
     (toggle-task-completed (task-id task))
     (define after-complete-tasks (get-all-tasks))
     (define completed-task (first after-complete-tasks))
     (check-true (task-completed? completed-task))
     
     ;; 检查未完成任务列表
     (define after-complete-incomplete (get-all-incomplete-tasks))
     (check-equal? (length after-complete-incomplete) 0)
     
     ;; 检查已完成任务列表
     (define after-complete-completed (get-all-completed-tasks))
     (check-equal? (length after-complete-completed) 1)
     
     ;; 3. 标记为未完成
     (toggle-task-completed (task-id completed-task))
     (define after-uncomplete-tasks (get-all-tasks))
     (define uncompleted-task (first after-uncomplete-tasks))
     (check-false (task-completed? uncompleted-task))
     
     ;; 检查未完成任务列表
     (define after-uncomplete-incomplete (get-all-incomplete-tasks))
     (check-equal? (length after-uncomplete-incomplete) 1)
     
     ;; 检查已完成任务列表
     (define after-uncomplete-completed (get-all-completed-tasks))
     (check-equal? (length after-uncomplete-completed) 0)
     
     ;; 4. 再次标记为完成
     (toggle-task-completed (task-id uncompleted-task))
     (define after-complete-again-tasks (get-all-tasks))
     (define completed-again-task (first after-complete-again-tasks))
     (check-true (task-completed? completed-again-task))
     
     ;; 5. 更新已完成任务
     (edit-task (task-id completed-again-task) list-id "更新后的已完成任务" "2023-01-02")
     (define updated-completed-task (first (get-all-tasks)))
     (check-equal? (task-text updated-completed-task) "更新后的已完成任务")
     (check-true (task-completed? updated-completed-task)) ; 更新后状态应该保持
     
     ;; 6. 删除已完成任务
     (delete-task (task-id updated-completed-task))
     (define after-delete-tasks (get-all-tasks))
     (check-equal? (length after-delete-tasks) 0)
     
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
     
     ;; 添加多个测试列表
     (add-list "分组测试列表1")
     (add-list "分组测试列表2")
     (add-list "分组测试列表3")
     (define lists (get-all-lists))
     (define list1-id (todo-list-id (first lists)))
     (define list2-id (todo-list-id (second lists)))
     (define list3-id (todo-list-id (third lists)))
     
     ;; 添加不同数量的任务到不同列表
     ;; 列表1：2个任务
     (add-task list1-id "列表1-任务1" "2023-01-01")
     (add-task list1-id "列表1-任务2" #f)
     
     ;; 列表2：3个任务
     (add-task list2-id "列表2-任务1" "2023-01-02")
     (add-task list2-id "列表2-任务2" "2023-01-03")
     (add-task list2-id "列表2-任务3" #f)
     
     ;; 列表3：1个任务
     (add-task list3-id "列表3-任务1" "2023-01-04")
     
     ;; 获取所有任务
     (define all-tasks (get-all-tasks))
     (check-equal? (length all-tasks) 6)
     
     ;; 测试分组功能
     (define grouped-tasks (group-tasks-by-list all-tasks))
     (check-pred list? grouped-tasks)
     (check-equal? (length grouped-tasks) 3) ; 应该有3个分组
     
     ;; 统计每个分组的任务数量
     (define group-counts (make-hash))
     (for ([group grouped-tasks])
       (define list-name (car group))
       (define tasks (cdr group))
       (hash-set! group-counts list-name (length tasks)))
     
     ;; 验证分组数量
     (check-equal? (hash-count group-counts) 3)
     
     ;; 关闭连接并清理
     (db:close-database)
     (when (file-exists? temp-db-path)
       (delete-file temp-db-path)))
   
   ;; 测试空日期任务的完整生命周期
   (test-case "测试空日期任务的完整生命周期" 
     ;; 创建唯一的临时数据库文件
     (define temp-db-path (format "./test/temp-null-date-integration-~a.db" (current-inexact-milliseconds)))
     
     ;; 确保临时文件不存在
     (when (file-exists? temp-db-path)
       (delete-file temp-db-path))
     
     ;; 连接数据库
     (db:connect-to-database temp-db-path)
     
     ;; 1. 创建测试列表
     (add-list "空日期测试列表")
     (define lists (get-all-lists))
     (define test-list (last lists))
     (define test-list-id (todo-list-id test-list))
     
     ;; 2. 测试添加多个空日期任务
     (add-task test-list-id "空日期任务1" #f)
     (add-task test-list-id "空日期任务2" #f)
     (add-task test-list-id "空日期任务3" #f)
     
     ;; 3. 测试获取所有任务
     (define all-tasks (get-all-tasks))
     (check-equal? (length all-tasks) 3)
     
     ;; 4. 测试所有任务都是空日期
     (for ([task all-tasks])
       (check-false (task-due-date task)))
     
     ;; 5. 测试按列表获取空日期任务
     (define list-tasks (get-tasks-by-list test-list-id))
     (check-equal? (length list-tasks) 3)
     
     ;; 6. 测试编辑空日期任务
     (define first-task (first list-tasks))
     (edit-task (task-id first-task) test-list-id "更新后的空日期任务" #f)
     
     ;; 7. 测试编辑后的任务仍然是空日期
     (define updated-task (findf (lambda (t) (= (task-id t) (task-id first-task))) (get-all-tasks)))
     (check-equal? (task-text updated-task) "更新后的空日期任务")
     (check-false (task-due-date updated-task))
     
     ;; 8. 测试空日期任务在不同视图中的显示
     (define all-view (get-tasks-by-view "all"))
     (check-equal? (length all-view) 3)
     
     (define planned-view (get-tasks-by-view "planned"))
     (check-equal? (length planned-view) 0) ; 空日期任务不应该出现在计划视图中
     
     ;; 9. 测试删除空日期任务
     (delete-task (task-id updated-task))
     (define tasks-after-delete (get-all-tasks))
     (check-equal? (length tasks-after-delete) 2)
     
     ;; 10. 测试切换空日期任务的完成状态
     (define second-task (first tasks-after-delete))
     (toggle-task-completed (task-id second-task))
     
     (define updated-task2 (findf (lambda (t) (= (task-id t) (task-id second-task))) (get-all-tasks)))
     (check-true (task-completed? updated-task2))
     (check-false (task-due-date updated-task2))
     
     ;; 11. 测试获取已完成的空日期任务
     (define completed-view (get-tasks-by-view "completed"))
     (check-equal? (length completed-view) 1)
     
     ;; 12. 测试获取未完成的空日期任务
     (define incomplete-view (get-all-incomplete-tasks))
     (check-equal? (length incomplete-view) 1)
     
     ;; 关闭连接并清理
     (db:close-database)
     (when (file-exists? temp-db-path)
       (delete-file temp-db-path)))
   ))

;; 运行测试套件
(run-tests integration-tests)