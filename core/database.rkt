#lang racket

(require db)

;; 全局数据库连接参数
(define current-db-connection (make-parameter #f))
(define current-db-path (make-parameter #f))

;; 连接到数据库
(define (connect-to-database db-path)
  (unless (file-exists? db-path)
    (printf "创建新数据库文件: ~a\n" db-path))
  
  (define conn (sqlite3-connect #:database db-path #:mode 'create))
  (current-db-connection conn)
  (current-db-path db-path)
  
  ;; 启用外键约束
  (query-exec conn "PRAGMA foreign_keys = ON")
  
  ;; 初始化数据库表
  (initialize-database conn)
  conn)

;; 关闭数据库连接
(define (close-database)
  (when (current-db-connection)
    (disconnect (current-db-connection))
    (current-db-connection #f)
    (current-db-path #f)))

;; 初始化数据库表
(define (initialize-database conn)
  ;; 创建任务列表表
  (query-exec conn "CREATE TABLE IF NOT EXISTS list (
                     list_id INTEGER PRIMARY KEY AUTOINCREMENT,
                     list_name TEXT NOT NULL
                     )")
  
  ;; 创建任务表
  (query-exec conn "CREATE TABLE IF NOT EXISTS task (
                     task_id INTEGER PRIMARY KEY AUTOINCREMENT,
                     list_id INTEGER NOT NULL,
                     task_text TEXT NOT NULL,
                     due_date TEXT NULL,
                     is_completed INTEGER NOT NULL DEFAULT 0,
                     priority INTEGER NOT NULL DEFAULT 0,
                     created_at TEXT NOT NULL,
                     FOREIGN KEY (list_id) REFERENCES list(list_id) ON DELETE CASCADE
                     )")
  
  ;; 检查并添加缺失的priority列（用于升级现有数据库）
  (with-handlers ([exn:fail? (lambda (e) 
                               ;; 忽略错误，继续执行
                               #f)])
    ;; 检查task表是否有priority列
    (define has-priority (query-value conn "SELECT COUNT(*) FROM pragma_table_info('task') WHERE name = 'priority'"))
    (when (= has-priority 0)
      ;; 添加priority列，默认值为0
      (query-exec conn "ALTER TABLE task ADD COLUMN priority INTEGER NOT NULL DEFAULT 0")))
  
  ;; 检查是否需要添加默认列表
  (define list-count (query-value conn "SELECT COUNT(*) FROM list"))
  (when (= list-count 0)
    (query-exec conn "INSERT INTO list (list_name) VALUES ('工作'), ('生活')")))

;; ------------------------
;; 列表相关操作
;; ------------------------

;; 获取所有列表
(define (get-all-lists)
  (define conn (current-db-connection))
  (query-rows conn "SELECT list_id, list_name FROM list ORDER BY list_id"))

;; 添加列表
(define (add-list list-name)
  (define conn (current-db-connection))
  (query-exec conn "INSERT INTO list (list_name) VALUES (?)
                   " list-name))

;; 更新列表名称
(define (update-list list-id new-name)
  (define conn (current-db-connection))
  (query-exec conn "UPDATE list SET list_name = ? WHERE list_id = ?
                   " new-name list-id))

;; 删除列表
(define (delete-list list-id)
  (define conn (current-db-connection))
  (query-exec conn "DELETE FROM list WHERE list_id = ?" list-id))

;; 获取列表名称
(define (get-list-name list-id)
  (define conn (current-db-connection))
  (query-value conn "SELECT list_name FROM list WHERE list_id = ?" list-id))

;; ------------------------
;; 任务相关操作
;; ------------------------

;; 获取所有任务
(define (get-all-tasks)
  (define conn (current-db-connection))
  (query-rows conn "SELECT task_id, list_id, task_text, due_date, is_completed, priority, created_at
                   FROM task
                   ORDER BY priority DESC, due_date NULLS LAST, created_at"))

;; 获取指定列表的任务
(define (get-tasks-by-list list-id)
  (define conn (current-db-connection))
  (query-rows conn "SELECT task_id, list_id, task_text, due_date, is_completed, priority, created_at
                   FROM task
                   WHERE list_id = ?
                   ORDER BY priority DESC, due_date NULLS LAST, created_at
                   " list-id))

;; 获取未完成的任务
(define (get-incomplete-tasks)
  (define conn (current-db-connection))
  (query-rows conn "SELECT task_id, list_id, task_text, due_date, is_completed, priority, created_at
                   FROM task
                   WHERE is_completed = 0
                   ORDER BY priority DESC, due_date NULLS LAST, created_at"))

;; 获取已完成的任务
(define (get-completed-tasks)
  (define conn (current-db-connection))
  (query-rows conn "SELECT task_id, list_id, task_text, due_date, is_completed, priority, created_at
                   FROM task
                   WHERE is_completed = 1
                   ORDER BY priority DESC, due_date NULLS LAST, created_at"))

;; 获取今天的任务
(define (get-today-tasks today-str)
  (define conn (current-db-connection))
  ;; 使用 LIKE 匹配日期部分，支持带时间的日期字符串
  (query-rows conn "SELECT task_id, list_id, task_text, due_date, is_completed, priority, created_at
                   FROM task
                   WHERE due_date LIKE ? AND is_completed = 0
                   ORDER BY priority DESC, due_date NULLS LAST, created_at
                   " (string-append today-str "%")))

;; 获取有截止日期的任务
(define (get-planned-tasks)
  (define conn (current-db-connection))
  (query-rows conn "SELECT task_id, list_id, task_text, due_date, is_completed, priority, created_at
                   FROM task
                   WHERE due_date IS NOT NULL AND due_date != '' AND is_completed = 0
                   ORDER BY priority DESC, due_date NULLS LAST, created_at"))

;; 添加任务 - 向后兼容版本
(define (add-task list-id task-text due-date [priority 1] [created-at (number->string (current-seconds))])
  (define conn (current-db-connection))
  (define sql-due-date (if due-date due-date sql-null))
  (define sql-priority (if priority priority 0))
  (define actual-created-at (if (number? created-at)
                               (number->string created-at)
                               created-at))
  (query-exec conn "INSERT INTO task (list_id, task_text, due_date, is_completed, priority, created_at)
                   VALUES (?, ?, ?, 0, ?, ?)
                   " list-id task-text sql-due-date sql-priority actual-created-at))

;; 更新任务
(define (update-task task-id list-id task-text due-date priority)
  (define conn (current-db-connection))
  (define sql-due-date (if due-date due-date sql-null))
  (define sql-priority (if priority priority 0))
  (query-exec conn "UPDATE task SET list_id = ?, task_text = ?, due_date = ?, priority = ?
                   WHERE task_id = ?
                   " list-id task-text sql-due-date sql-priority task-id))

;; 切换任务完成状态
(define (toggle-task-completed task-id)
  (define conn (current-db-connection))
  (query-exec conn "UPDATE task SET is_completed = 1 - is_completed
                   WHERE task_id = ?
                   " task-id))

;; 删除任务
(define (delete-task task-id)
  (define conn (current-db-connection))
  (query-exec conn "DELETE FROM task WHERE task_id = ?" task-id))

;; 搜索任务
(define (search-tasks keyword)
  (define conn (current-db-connection))
  (query-rows conn "SELECT task_id, list_id, task_text, due_date, is_completed, priority, created_at
                   FROM task
                   WHERE task_text LIKE ?
                   ORDER BY priority DESC, due_date NULLS LAST, created_at
                   " (string-append "%" keyword "%")))

(provide connect-to-database
         close-database
         get-all-lists
         add-list
         update-list
         delete-list
         get-list-name
         get-all-tasks
         get-tasks-by-list
         get-incomplete-tasks
         get-completed-tasks
         get-today-tasks
         get-planned-tasks
         add-task
         update-task
         toggle-task-completed
         delete-task
         search-tasks
         current-db-connection
         current-db-path)
