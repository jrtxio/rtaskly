#lang racket

;; Task core module - defines task structure and task operation functions
;; Includes task query, add, edit, delete, and other functionality

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

;; Task structure definition
(struct task (id list-id text due-date completed? created-at list-name) #:transparent)

;; Convert database query result to task structure
(define (row->task row)
  (define list-id (vector-ref row 1)) ; list_id
  (define list-name 
    (with-handlers ([exn:fail? (lambda (e) "Unknown List")])
      (db:get-list-name list-id)))
  
  (task (vector-ref row 0)  ; task_id
        list-id  ; list_id
        (vector-ref row 2)  ; task_text
        (if (sql-null? (vector-ref row 3)) #f (vector-ref row 3))  ; due_date
        (= (vector-ref row 4) 1)  ; is_completed
        (string->number (vector-ref row 5))  ; created_at (convert to number)
        list-name))

;; Convert multiple database query results to task structure list
(define (rows->tasks rows)
  (map row->task rows))

;; ------------------------
;; Task query functionality
;; ------------------------

;; Get all tasks
(define (get-all-tasks)
  (rows->tasks (db:get-all-tasks)))

;; Get tasks for specific list
(define (get-tasks-by-list list-id)
  (rows->tasks (db:get-tasks-by-list list-id)))

;; Get today's tasks
(define (get-today-tasks)
  (rows->tasks (db:get-today-tasks (get-current-date-string))))

;; Get planned tasks (with due date and not completed)
(define (get-planned-tasks)
  (rows->tasks (db:get-planned-tasks)))

;; Get all incomplete tasks
(define (get-all-incomplete-tasks)
  (rows->tasks (db:get-incomplete-tasks)))

;; Get all completed tasks
(define (get-all-completed-tasks)
  (rows->tasks (db:get-completed-tasks)))

;; ------------------------
;; Task operation functionality
;; ------------------------

;; Add task - backward compatible version
(define (add-task list-id task-text due-date)
  (define created-at (current-seconds))
  (db:add-task list-id task-text due-date created-at))

;; Edit task - backward compatible version
(define (edit-task task-id list-id task-text due-date)
  (db:update-task task-id list-id task-text due-date))

;; Toggle task completion status
(define (toggle-task-completed task-id)
  (db:toggle-task-completed task-id))

;; Delete task
(define (delete-task task-id)
  (db:delete-task task-id))

;; Search tasks
(define (search-tasks keyword)
  (rows->tasks (db:search-tasks keyword)))

;; Get tasks by view type
(define (get-tasks-by-view view-type [list-id #f] [keyword #f])
  (cond
    [(string=? view-type "today") (get-today-tasks)]
    [(string=? view-type "planned") (get-planned-tasks)]
    [(string=? view-type "all") (get-all-incomplete-tasks)]
    [(string=? view-type "completed") (get-all-completed-tasks)]
    [(string=? view-type "list") (if list-id (get-tasks-by-list list-id) '())]
    [(string=? view-type "search") (if keyword (search-tasks keyword) '())]
    [else '()]))

;; Group tasks by list
(define (group-tasks-by-list tasks)
  (define groups (make-hash))
  
  ;; Group tasks by list
  (for ([task tasks])
    (define list-name (task-list-name task))
    (hash-set! groups list-name 
               (cons task (hash-ref groups list-name '()))))
  
  ;; Convert to ordered list
  (hash->list groups))
