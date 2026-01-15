#lang racket

;; Database core module - handles database connections and low-level data operations
;; Includes database connection, closing, initialization, and CRUD operations for tasks and lists

(require db)

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

;; Global database connection parameters
(define current-db-connection (make-parameter #f))
(define current-db-path (make-parameter #f))

;; Connect to database
;; Returns database connection or #f on failure
(define (connect-to-database db-path)
  (with-handlers ([exn:fail? (lambda (e) 
                               (eprintf "Database connection error: ~a\n" (exn-message e))
                               #f)])
    (define conn (sqlite3-connect #:database db-path #:mode 'create))
    (current-db-connection conn)
    (current-db-path db-path)
    
    ;; Enable foreign key constraints
    (query-exec conn "PRAGMA foreign_keys = ON")
    
    ;; Initialize database tables
    (initialize-database conn)
    conn))

;; Close database connection
(define (close-database)
  (with-handlers ([exn:fail? (lambda (e) 
                               (eprintf "Error closing database: ~a\n" (exn-message e)))])
    (when (current-db-connection)
      (disconnect (current-db-connection))
      (current-db-connection #f)
      (current-db-path #f))))

;; Initialize database tables
(define (initialize-database conn)
  (with-handlers ([exn:fail? (lambda (e) 
                               (eprintf "Error initializing database: ~a\n" (exn-message e)))])
    ;; Create task lists table
    (query-exec conn "CREATE TABLE IF NOT EXISTS list (
                     list_id INTEGER PRIMARY KEY AUTOINCREMENT,
                     list_name TEXT NOT NULL
                     )")
    
    ;; Create tasks table
    (query-exec conn "CREATE TABLE IF NOT EXISTS task (
                     task_id INTEGER PRIMARY KEY AUTOINCREMENT,
                     list_id INTEGER NOT NULL,
                     task_text TEXT NOT NULL,
                     due_date TEXT NULL,
                     is_completed INTEGER NOT NULL DEFAULT 0,
                     created_at TEXT NOT NULL,
                     FOREIGN KEY (list_id) REFERENCES list(list_id) ON DELETE CASCADE
                     )")
    
    ;; Check if default lists need to be added
    (define list-count (query-value conn "SELECT COUNT(*) FROM list"))
    (when (= list-count 0)
      (query-exec conn "INSERT INTO list (list_name) VALUES ('Work'), ('Personal')"))))

;; ------------------------
;; List-related operations
;; ------------------------

;; Get all lists
;; Returns list of lists with id and name
(define (get-all-lists)
  (with-handlers ([exn:fail? (lambda (e) 
                               (eprintf "Error getting all lists: ~a\n" (exn-message e))
                               '())])
    (define conn (current-db-connection))
    (if conn
        (query-rows conn "SELECT list_id, list_name FROM list ORDER BY list_id")
        '())))

;; Add a new list
;; Returns the ID of the newly created list
(define (add-list list-name)
  (with-handlers ([exn:fail? (lambda (e) 
                               (eprintf "Error adding list: ~a\n" (exn-message e))
                               #f)])
    (define conn (current-db-connection))
    (if conn
        (begin
          (query-exec conn "INSERT INTO list (list_name) VALUES (?)
                           " list-name)
          (query-value conn "SELECT last_insert_rowid()"))
        #f)))

;; Update list name
;; Returns #t on success, #f on failure
(define (update-list list-id new-name)
  (with-handlers ([exn:fail? (lambda (e) 
                               (eprintf "Error updating list: ~a\n" (exn-message e))
                               #f)])
    (define conn (current-db-connection))
    (if conn
        (begin
          (query-exec conn "UPDATE list SET list_name = ? WHERE list_id = ?
                           " new-name list-id)
          #t)
        #f)))

;; Delete list
;; Returns #t on success, #f on failure
(define (delete-list list-id)
  (with-handlers ([exn:fail? (lambda (e) 
                               (eprintf "Error deleting list: ~a\n" (exn-message e))
                               #f)])
    (define conn (current-db-connection))
    (if conn
        (begin
          (query-exec conn "DELETE FROM list WHERE list_id = ?" list-id)
          #t)
        #f)))

;; Get list name by ID
;; Returns list name or #f if not found
(define (get-list-name list-id)
  (with-handlers ([exn:fail? (lambda (e) 
                               (eprintf "Error getting list name: ~a\n" (exn-message e))
                               #f)])
    (define conn (current-db-connection))
    (if conn
        (query-value conn "SELECT list_name FROM list WHERE list_id = ?" list-id)
        #f)))

;; ------------------------
;; Task-related operations
;; ------------------------

;; Get all tasks
;; Returns list of all tasks
(define (get-all-tasks)
  (with-handlers ([exn:fail? (lambda (e) 
                               (eprintf "Error getting all tasks: ~a\n" (exn-message e))
                               '())])
    (define conn (current-db-connection))
    (if conn
        (query-rows conn "SELECT task_id, list_id, task_text, due_date, is_completed, created_at
                         FROM task
                         ORDER BY due_date NULLS LAST, created_at")
        '())))

;; Get tasks by list ID
;; Returns list of tasks for the specified list
(define (get-tasks-by-list list-id)
  (with-handlers ([exn:fail? (lambda (e) 
                               (eprintf "Error getting tasks by list: ~a\n" (exn-message e))
                               '())])
    (define conn (current-db-connection))
    (if conn
        (query-rows conn "SELECT task_id, list_id, task_text, due_date, is_completed, created_at
                         FROM task
                         WHERE list_id = ? AND is_completed = 0
                         ORDER BY due_date NULLS LAST, created_at
                         " list-id)
        '())))

;; Get incomplete tasks
;; Returns list of incomplete tasks
(define (get-incomplete-tasks)
  (with-handlers ([exn:fail? (lambda (e) 
                               (eprintf "Error getting incomplete tasks: ~a\n" (exn-message e))
                               '())])
    (define conn (current-db-connection))
    (if conn
        (query-rows conn "SELECT task_id, list_id, task_text, due_date, is_completed, created_at
                         FROM task
                         WHERE is_completed = 0
                         ORDER BY due_date NULLS LAST, created_at")
        '())))

;; Get completed tasks
;; Returns list of completed tasks
(define (get-completed-tasks)
  (with-handlers ([exn:fail? (lambda (e) 
                               (eprintf "Error getting completed tasks: ~a\n" (exn-message e))
                               '())])
    (define conn (current-db-connection))
    (if conn
        (query-rows conn "SELECT task_id, list_id, task_text, due_date, is_completed, created_at
                         FROM task
                         WHERE is_completed = 1
                         ORDER BY due_date NULLS LAST, created_at")
        '())))

;; Get today's tasks
;; Returns list of tasks due today
(define (get-today-tasks today-str)
  (with-handlers ([exn:fail? (lambda (e) 
                               (eprintf "Error getting today's tasks: ~a\n" (exn-message e))
                               '())])
    (define conn (current-db-connection))
    (if conn
        ;; Use LIKE to match date part, supports date strings with time
        (query-rows conn "SELECT task_id, list_id, task_text, due_date, is_completed, created_at
                         FROM task
                         WHERE due_date LIKE ? AND is_completed = 0
                         ORDER BY due_date NULLS LAST, created_at
                         " (string-append today-str "%"))
        '())))

;; Get planned tasks (with due date)
;; Returns list of tasks with due date
(define (get-planned-tasks)
  (with-handlers ([exn:fail? (lambda (e) 
                               (eprintf "Error getting planned tasks: ~a\n" (exn-message e))
                               '())])
    (define conn (current-db-connection))
    (if conn
        (query-rows conn "SELECT task_id, list_id, task_text, due_date, is_completed, created_at
                         FROM task
                         WHERE due_date IS NOT NULL AND due_date != '' AND is_completed = 0
                         ORDER BY due_date NULLS LAST, created_at")
        '())))

;; Add task - backward compatible version
;; Returns #t on success, #f on failure
(define (add-task list-id task-text due-date [created-at (number->string (current-seconds))])
  (with-handlers ([exn:fail? (lambda (e) 
                               (eprintf "Error adding task: ~a\n" (exn-message e))
                               #f)])
    (define conn (current-db-connection))
    (if conn
        (let (
              (sql-due-date (if due-date due-date sql-null))
              (actual-created-at (if (number? created-at)
                                   (number->string created-at)
                                   created-at)))
          (query-exec conn "INSERT INTO task (list_id, task_text, due_date, is_completed, created_at)
                           VALUES (?, ?, ?, 0, ?)
                           " list-id task-text sql-due-date actual-created-at)
          #t)
        #f)))

;; Update task
;; Returns #t on success, #f on failure
(define (update-task task-id list-id task-text due-date)
  (with-handlers ([exn:fail? (lambda (e) 
                               (eprintf "Error updating task: ~a\n" (exn-message e))
                               #f)])
    (define conn (current-db-connection))
    (if conn
        (let (
              (sql-due-date (if due-date due-date sql-null)))
          (query-exec conn "UPDATE task SET list_id = ?, task_text = ?, due_date = ?
                           WHERE task_id = ?
                           " list-id task-text sql-due-date task-id)
          #t)
        #f)))

;; Toggle task completed status
;; Returns #t on success, #f on failure
(define (toggle-task-completed task-id)
  (with-handlers ([exn:fail? (lambda (e) 
                               (eprintf "Error toggling task status: ~a\n" (exn-message e))
                               #f)])
    (define conn (current-db-connection))
    (if conn
        (begin
          (query-exec conn "UPDATE task SET is_completed = 1 - is_completed
                           WHERE task_id = ?
                           " task-id)
          #t)
        #f)))

;; Delete task
;; Returns #t on success, #f on failure
(define (delete-task task-id)
  (with-handlers ([exn:fail? (lambda (e) 
                               (eprintf "Error deleting task: ~a\n" (exn-message e))
                               #f)])
    (define conn (current-db-connection))
    (if conn
        (begin
          (query-exec conn "DELETE FROM task WHERE task_id = ?" task-id)
          #t)
        #f)))

;; Search tasks
;; Returns list of tasks matching the keyword
(define (search-tasks keyword)
  (with-handlers ([exn:fail? (lambda (e) 
                               (eprintf "Error searching tasks: ~a\n" (exn-message e))
                               '())])
    (define conn (current-db-connection))
    (if conn
        (query-rows conn "SELECT task_id, list_id, task_text, due_date, is_completed, created_at
                         FROM task
                         WHERE task_text LIKE ?
                         ORDER BY due_date NULLS LAST, created_at
                         " (string-append "%" keyword "%"))
        '())))
