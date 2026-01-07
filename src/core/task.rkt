#lang racket

;; 任务核心模块，定义任务结构体和任务操作函数
;; 包含任务查询、添加、编辑、删除等功能

(require db
         (only-in db sql-null?)
         (prefix-in db: "database.rkt")
         (prefix-in lst: "list.rkt")
         "../utils/date.rkt")

(provide (struct-out task)
         row->task
         rows->tasks
         get-all-tasks
         get-tasks-by-list
         get-today-tasks
         get-planned-tasks
         get-all-incomplete-tasks
         get-all-completed-tasks
         search-tasks
         add-task
         edit-task
         toggle-task-completed
         delete-task
         get-tasks-by-view
         group-tasks-by-list)

;; 任务结构体定义
(struct task (id list-id text due-date completed? created-at list-name) #:transparent)

;; 将数据库查询结果转换为任务结构体
(define (row->task row)
  (define list-id (vector-ref row 1)) ; list_id
  (define list-name 
    (with-handlers ([exn:fail? (lambda (e) "未知列表")])
      (db:get-list-name list-id)))
  
  (task (vector-ref row 0)  ; task_id
        list-id  ; list_id
        (vector-ref row 2)  ; task_text
        (if (sql-null? (vector-ref row 3)) #f (vector-ref row 3))  ; due_date
        (= (vector-ref row 4) 1)  ; is_completed
        (string->number (vector-ref row 5))  ; created_at (转换为数字)
        list-name))

;; 将多个数据库查询结果转换为任务结构体列表
(define (rows->tasks rows)
  (map row->task rows))

;; ------------------------
;; 任务查询功能
;; ------------------------

;; 获取所有任务
(define (get-all-tasks)
  (rows->tasks (db:get-all-tasks)))

;; 获取特定列表的任务
(define (get-tasks-by-list list-id)
  (rows->tasks (db:get-tasks-by-list list-id)))

;; 获取今天的任务
(define (get-today-tasks)
  (rows->tasks (db:get-today-tasks (get-current-date-string))))

;; 获取计划任务（有截止日期且未完成）
(define (get-planned-tasks)
  (rows->tasks (db:get-planned-tasks)))

;; 获取所有未完成任务
(define (get-all-incomplete-tasks)
  (rows->tasks (db:get-incomplete-tasks)))

;; 获取所有已完成任务
(define (get-all-completed-tasks)
  (rows->tasks (db:get-completed-tasks)))

;; ------------------------
;; 任务操作功能
;; ------------------------

;; 添加任务 - 向后兼容版本
(define (add-task list-id task-text due-date)
  (define created-at (current-seconds))
  (db:add-task list-id task-text due-date created-at))

;; 编辑任务 - 向后兼容版本
(define (edit-task task-id list-id task-text due-date)
  (db:update-task task-id list-id task-text due-date))

;; 切换任务完成状态
(define (toggle-task-completed task-id)
  (db:toggle-task-completed task-id))

;; 删除任务
(define (delete-task task-id)
  (db:delete-task task-id))

;; 搜索任务
(define (search-tasks keyword)
  (rows->tasks (db:search-tasks keyword)))

;; 根据视图类型获取任务
(define (get-tasks-by-view view-type [list-id #f] [keyword #f])
  (cond
    [(string=? view-type "today") (get-today-tasks)]
    [(string=? view-type "planned") (get-planned-tasks)]
    [(string=? view-type "all") (get-all-incomplete-tasks)]
    [(string=? view-type "completed") (get-all-completed-tasks)]
    [(string=? view-type "list") (if list-id (get-tasks-by-list list-id) '())]
    [(string=? view-type "search") (if keyword (search-tasks keyword) '())]
    [else '()]))

;; 按列表分组任务
(define (group-tasks-by-list tasks)
  (define groups (make-hash))
  
  ;; 将任务按列表分组
  (for ([task tasks])
    (define list-name (task-list-name task))
    (hash-set! groups list-name 
               (cons task (hash-ref groups list-name '()))))
  
  ;; 转换为有序列表
  (hash->list groups))
