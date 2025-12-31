#lang racket

(require rackunit
         rackunit/text-ui
         "../core/list.rkt"
         (prefix-in db: "../core/database.rkt"))

;; 定义测试套件
(define list-tests
  (test-suite
   "列表管理测试"
   
   ;; 测试列表管理功能
   (test-case "测试列表管理功能" 
     ;; 创建唯一的临时数据库文件，使用更精确的时间戳
     (define temp-db-path (format "./test/temp-test-~a.db" (current-inexact-milliseconds)))
     
     ;; 确保临时文件不存在
     (when (file-exists? temp-db-path)
       (delete-file temp-db-path))
     
     ;; 连接数据库
     (db:connect-to-database temp-db-path)
     
     ;; 测试获取所有列表（默认应该有2个列表）
     (define initial-lists (get-all-lists))
     (check-pred list? initial-lists)
     (check-equal? (length initial-lists) 2)
     
     ;; 测试添加列表
     (db:add-list "学习")
     (db:add-list "娱乐")
     (db:add-list "健康")
     
     (define lists-after-add (get-all-lists))
     (check-equal? (length lists-after-add) 5)
     
     ;; 测试获取列表名称
     (define first-list (first lists-after-add))
     (check-equal? (todo-list-name first-list) "工作")
     
     ;; 测试根据ID获取列表
     (define list-id (todo-list-id first-list))
     (define found-list (get-list-by-id list-id))
     (check-equal? found-list first-list)
     
     ;; 测试更新列表
     (db:update-list list-id "工作列表")
     (define updated-list (get-list-by-id list-id))
     (check-equal? (todo-list-name updated-list) "工作列表")
     
     ;; 测试获取默认列表
     (define default-list (get-default-list))
     (check-pred todo-list? default-list)
     (check-equal? (todo-list-name default-list) "工作列表")
     
     ;; 测试删除列表
     (db:delete-list list-id)
     (define lists-after-delete (get-all-lists))
     (check-equal? (length lists-after-delete) 4)
     
     ;; 关闭连接并清理
     (db:close-database)
     (when (file-exists? temp-db-path)
       (delete-file temp-db-path)))
   ))

;; 运行测试套件
(run-tests list-tests)