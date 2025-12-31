#lang racket

(require (prefix-in db: "database.rkt"))

;; 列表结构体定义
(struct todo-list (id name) #:transparent)

;; 将数据库查询结果转换为列表结构体
(define (row->todo-list row)
  (todo-list (vector-ref row 0)  ; list_id
             (vector-ref row 1))) ; list_name

;; 将多个数据库查询结果转换为列表结构体列表
(define (rows->todo-lists rows)
  (map row->todo-list rows))

;; ------------------------
;; 列表查询功能
;; ------------------------

;; 获取所有列表
(define (get-all-lists)
  (rows->todo-lists (db:get-all-lists)))

;; 根据ID获取列表
(define (get-list-by-id list-id)
  (define all-lists (get-all-lists))
  (findf (lambda (lst) (= (todo-list-id lst) list-id)) all-lists))

;; ------------------------
;; 列表操作功能
;; ------------------------

;; 添加列表
(define (add-list list-name)
  (db:add-list list-name))

;; 更新列表名称
(define (update-list list-id new-name)
  (db:update-list list-id new-name))

;; 删除列表
(define (delete-list list-id)
  (db:delete-list list-id))

;; 获取默认列表（第一个列表）
(define (get-default-list)
  (define all-lists (get-all-lists))
  (if (not (empty? all-lists))
      (first all-lists)
      #f))

(provide (struct-out todo-list)
         row->todo-list
         rows->todo-lists
         get-all-lists
         get-list-by-id
         add-list
         update-list
         delete-list
         get-default-list)
