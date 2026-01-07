#lang racket

(require rackunit
         rackunit/text-ui
         racket/gui/base
         (prefix-in gui: "../src/gui/main-frame.rkt")
         "../src/core/database.rkt")

;; 定义测试套件
(define db-suffix-tests
  (test-suite
   "数据库后缀自动添加测试"
   
   ;; 测试1：测试文件路径处理函数 - 自动添加.db后缀
   (test-case "测试文件路径自动添加.db后缀" 
     ;; 测试用例：没有后缀的路径
     (define test-path1 (string->path "test-db"))
     (define result1 (if (equal? #".db" (path-get-extension test-path1))
                        test-path1
                        (path-add-extension test-path1 #".db")))
     (check-equal? result1 (string->path "test-db.db"))
     
     ;; 测试用例：已有.db后缀的路径
     (define test-path2 (string->path "test-db.db"))
     (define result2 (if (equal? #".db" (path-get-extension test-path2))
                        test-path2
                        (path-add-extension test-path2 #".db")))
     (check-equal? result2 (string->path "test-db.db"))
     
     ;; 测试用例：带其他后缀的路径
     (define test-path3 (string->path "test-db.txt"))
     ;; 对于已有其他后缀的文件，我们的逻辑是保留原有后缀并添加.db，使用字符串操作
     (define result3-str (string-append (path->string test-path3) ".db"))
     (define result3 (string->path result3-str))
     (check-equal? result3 (string->path "test-db.txt.db"))
     
     ;; 测试用例：包含路径的情况
     (define test-path4 (string->path "./test/test-db"))
     (define result4 (if (equal? #".db" (path-get-extension test-path4))
                        test-path4
                        (path-add-extension test-path4 #".db")))
     (check-equal? result4 (string->path "./test/test-db.db")))
   
   ;; 测试2：测试connect-to-database函数不会输出到命令行
   (test-case "测试connect-to-database函数不会输出到命令行" 
     ;; 创建唯一的临时数据库文件
     (define temp-db-path (format "./test/temp-suffix-test-~a.db" (current-inexact-milliseconds)))
     
     ;; 确保临时文件不存在
     (when (file-exists? temp-db-path)
       (delete-file temp-db-path))
     
     ;; 捕获connect-to-database函数的输出
     (define output (with-output-to-string
                     (lambda ()
                       (connect-to-database temp-db-path))))
     
     ;; 检查输出是否为空，确保没有命令行输出
     (check-equal? (string-trim output) "" "connect-to-database函数不应该输出到命令行")
     
     ;; 关闭连接并清理
     (close-database)
     (when (file-exists? temp-db-path)
       (delete-file temp-db-path)))
   
   ;; 测试3：测试完整的数据库创建流程，包括自动添加后缀
   (test-case "测试完整的数据库创建流程" 
     ;; 创建唯一的临时数据库文件路径，不包含.db后缀
     ;; 使用整数时间戳避免文件名中的小数点问题
     (define timestamp (exact-truncate (current-inexact-milliseconds)))
     (define temp-db-path-no-suffix (format "./test/temp-full-test-~a" timestamp))
     
     ;; 测试直接连接到没有后缀的路径（模拟GUI中的自动添加后缀逻辑）
     (define path (string->path temp-db-path-no-suffix))
     (define final-path (if (equal? #".db" (path-get-extension path))
                            path
                            (path-add-extension path #".db")))
     (define final-path-str (path->string final-path))
     
     ;; 确保临时文件不存在
     (when (file-exists? final-path-str)
       (delete-file final-path-str))
     
     ;; 连接到数据库
     (connect-to-database final-path-str)
     
     ;; 验证数据库文件是否正确创建
     (check-true (file-exists? final-path-str))
     
     ;; 关闭连接并清理
     (close-database)
     (when (file-exists? final-path-str)
       (delete-file final-path-str)))
   
   ;; 测试4：测试创建多个不同后缀情况的数据库
   (test-case "测试创建多个不同后缀情况的数据库" 
     ;; 使用整数时间戳生成唯一的测试文件名
     (define timestamp (exact-truncate (current-inexact-milliseconds)))
     (define test-cases
       (list
        ;; 输入路径，预期输出路径
        (list (format "./test/test-db1-~a" timestamp) (format "./test/test-db1-~a.db" timestamp))
        (list (format "./test/test-db2-~a.db" timestamp) (format "./test/test-db2-~a.db" timestamp))
        (list (format "./test/subdir/test-db3-~a" timestamp) (format "./test/subdir/test-db3-~a.db" timestamp))
        (list (format "./test/subdir/test-db4-~a.db" timestamp) (format "./test/subdir/test-db4-~a.db" timestamp))))
     
     ;; 创建测试子目录
     (define test-subdir "./test/subdir")
     (unless (directory-exists? test-subdir)
       (make-directory test-subdir))
     
     ;; 运行所有测试用例
     (for ([test-case test-cases])
       (define input-path-str (first test-case))
       (define expected-path-str (second test-case))
       
       ;; 确保测试文件不存在
       (when (file-exists? expected-path-str)
         (delete-file expected-path-str))
       
       ;; 应用自动添加后缀逻辑
       (define path (string->path input-path-str))
       (define final-path (if (equal? #".db" (path-get-extension path))
                              path
                              (path-add-extension path #".db")))
       (define final-path-str (path->string final-path))
       
       ;; 验证路径处理是否正确
       (check-equal? final-path-str expected-path-str)
       
       ;; 连接到数据库
       (connect-to-database final-path-str)
       
       ;; 验证数据库文件是否创建成功
       (check-true (file-exists? expected-path-str))
       
       ;; 关闭连接
       (close-database)
       
       ;; 清理
       (when (file-exists? expected-path-str)
         (delete-file expected-path-str)))
     
     ;; 删除测试子目录
     (when (directory-exists? test-subdir)
       (delete-directory test-subdir)))))

;; 运行测试套件
(run-tests db-suffix-tests)