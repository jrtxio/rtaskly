#lang racket

;; 运行所有测试文件
(displayln "\n=== 运行所有测试 ===\n")

;; 运行日期工具测试
(displayln "运行日期工具测试...")
(system "racket test/test-date.rkt")

;; 运行数据库操作测试
(displayln "\n运行数据库操作测试...")
(system "racket test/test-database.rkt")

;; 运行列表管理测试
(displayln "\n运行列表管理测试...")
(system "racket test/test-list.rkt")

;; 运行任务管理测试
(displayln "\n运行任务管理测试...")
(system "racket test/test-task.rkt")

(displayln "\n=== 所有测试运行完成 ===\n")
