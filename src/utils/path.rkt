#lang racket

(require racket/path
         racket/file)

;; Get application default directory
(define (get-default-app-dir)
  (with-handlers ([exn:fail? (lambda (e) 
                               (eprintf "Error getting default app directory: ~a\n" (exn-message e))
                               (find-system-path 'home-dir))])
    (let* ([home-dir (find-system-path 'home-dir)]
           [app-dir (build-path home-dir ".taskly")])
      (unless (directory-exists? app-dir)
        (make-directory* app-dir))
      app-dir)))

;; Get default database file path
(define (get-default-db-path)
  (with-handlers ([exn:fail? (lambda (e) 
                               (eprintf "Error getting default DB path: ~a\n" (exn-message e))
                               (build-path (find-system-path 'home-dir) "tasks.db"))])
    (build-path (get-default-app-dir) "tasks.db")))

;; Get configuration file path
(define (get-config-file-path)
  (with-handlers ([exn:fail? (lambda (e) 
                               (eprintf "Error getting config file path: ~a\n" (exn-message e))
                               (build-path (find-system-path 'home-dir) "config.ini"))])
    (build-path (get-default-app-dir) "config.ini")))

;; Read configuration file
(define (read-config)
  (with-handlers ([exn:fail? (lambda (e) 
                               (eprintf "Error reading config file: ~a\n" (exn-message e))
                               '())])
    (let ([config-path (get-config-file-path)])
      (if (file-exists? config-path)
          (with-input-from-file config-path
            (lambda ()
              (let loop ([configs '()])
                (let ([line (read-line)])
                  (if (eof-object? line)
                      configs
                      (let ([trimmed-line (string-trim line)])
                        (if (and (non-empty-string? trimmed-line)
                                 (not (string-prefix? trimmed-line ";")))
                            (let ([parts (string-split trimmed-line "=" #:trim? #t)])
                              (if (= (length parts) 2)
                                  (loop (cons (cons (first parts) (second parts)) configs))
                                  (loop configs)))
                            (loop configs))))))))
          '()))))

;; Save configuration file
(define (save-config configs)
  (with-handlers ([exn:fail? (lambda (e) 
                               (eprintf "Error saving config file: ~a\n" (exn-message e))
                               #f)])
    (let ([config-path (get-config-file-path)])
      (with-output-to-file config-path
        #:exists 'replace
        (lambda ()
          (for ([config-pair configs])
            (fprintf (current-output-port) "~a=~a\n" (car config-pair) (cdr config-pair)))))
      #t)))

;; Get specific configuration item
(define (get-config key [default #f])
  (with-handlers ([exn:fail? (lambda (e) 
                               (eprintf "Error getting config: ~a\n" (exn-message e))
                               default)])
    (let ([configs (read-config)])
      (let ([value (assoc key configs)])
        (if value
            (cdr value)
            default)))))

;; Set specific configuration item
(define (set-config key value)
  (with-handlers ([exn:fail? (lambda (e) 
                               (eprintf "Error setting config: ~a\n" (exn-message e))
                               #f)])
    (let ([configs (read-config)])
      (let ([new-configs (cons (cons key value) 
                               (filter (lambda (pair) (not (equal? (car pair) key))) configs))])
        (save-config new-configs)))))

;; Ensure directory exists, create if not
(define (ensure-directory-exists dir-path)
  (with-handlers ([exn:fail? (lambda (e) 
                               (eprintf "Error ensuring directory exists: ~a\n" (exn-message e))
                               #f)])
    (unless (directory-exists? dir-path)
      (make-directory* dir-path))
    #t))

;; Check if file exists safely
(define (safe-file-exists? path)
  (with-handlers ([exn:fail? (lambda (e) 
                               (eprintf "Error checking file existence: ~a\n" (exn-message e))
                               #f)])
    (let ([abs-path (if (relative-path? path) 
                        (build-path (current-directory) path)
                        path)])
      (file-exists? abs-path))))

;; Convert relative path to absolute path
(define (get-absolute-path path)
  (with-handlers ([exn:fail? (lambda (e) 
                               (eprintf "Error getting absolute path: ~a\n" (exn-message e))
                               (if (string? path) path (path->string path)))])
    (let ([path-obj (if (string? path)
                        (string->path path)
                        path)])
      (path->string 
       (if (relative-path? path-obj)
           (build-path (current-directory) path-obj)
           path-obj)))))

;; Get filename (without path)
(define (get-filename path)
  (with-handlers ([exn:fail? (lambda (e) 
                               (eprintf "Error getting filename: ~a\n" (exn-message e))
                               "")])
    (path->string (file-name-from-path path))))

(provide get-default-app-dir
         get-default-db-path
         get-config-file-path
         read-config
         save-config
         get-config
         set-config
         ensure-directory-exists
         safe-file-exists?
         get-absolute-path
         get-filename)
