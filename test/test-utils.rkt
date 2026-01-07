#lang racket

(require db
         (prefix-in db: "../src/core/database.rkt"))

;; 创建唯一的临时数据库文件
(define (create-temp-db-path [prefix "temp-test"]) 
  (format "./test/~a-~a.db" prefix (current-inexact-milliseconds)))

;; 确保临时文件不存在
(define (ensure-file-not-exists file-path)
  (when (file-exists? file-path)
    (delete-file file-path)))

;; 清理临时文件
(define (cleanup-temp-file file-path)
  (when (file-exists? file-path)
    (delete-file file-path)))

;; 测试前置条件：创建临时数据库并连接
(define (setup-db [prefix "temp-test"])
  (define temp-db-path (create-temp-db-path prefix))
  (ensure-file-not-exists temp-db-path)
  (db:connect-to-database temp-db-path)
  temp-db-path)

;; 测试后置条件：关闭数据库连接并清理临时文件
(define (teardown-db temp-db-path)
  (db:close-database)
  (cleanup-temp-file temp-db-path))

(provide create-temp-db-path
         ensure-file-not-exists
         cleanup-temp-file
         setup-db
         teardown-db)