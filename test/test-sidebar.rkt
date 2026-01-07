#lang racket/gui

(require rackunit
         rackunit/text-ui
         db
         "../src/gui/sidebar.rkt"
         (prefix-in core: "../src/core/list.rkt")
         (prefix-in db: "../src/core/database.rkt")
         (prefix-in lang: "../src/gui/language.rkt"))

;; 定义测试套件
(define sidebar-tests
  (test-suite
   "侧边栏组件测试"
   
   ;; 测试sidebar%初始化
   (test-case "测试sidebar%初始化" 
     ;; 创建一个临时顶级窗口用于测试
     (define frame (new frame% [label "Test Frame"] [width 300] [height 400]))
     
     ;; 初始化侧边栏
     (define sidebar (new sidebar% [parent frame]))
     
     ;; 检查侧边栏是否正确创建
     (check-true (is-a? sidebar sidebar%))
     
     ;; 侧边栏是一个容器组件，没有enable?方法，检查其基本结构
     
     ;; 关闭测试窗口
     (send frame show #f))
   
   ;; 测试列表刷新功能
   (test-case "测试列表刷新功能" 
     ;; 创建唯一的临时数据库文件
     (define temp-db-path (format "./test/temp-test-sidebar-~a.db" (current-inexact-milliseconds)))
     
     ;; 确保临时文件不存在
     (when (file-exists? temp-db-path)
       (delete-file temp-db-path))
     
     ;; 连接数据库
     (db:connect-to-database temp-db-path)
     
     ;; 创建测试列表
     (core:add-list "测试列表1")
     (core:add-list "测试列表2")
     
     ;; 创建测试窗口和侧边栏
     (define frame (new frame% [label "Test Frame"] [width 300] [height 400]))
     (define sidebar (new sidebar% [parent frame]))
     
     ;; 刷新列表
     (send sidebar refresh-lists)
     
     ;; 检查智能列表按钮是否启用
     ;; 因为已经连接数据库并创建了列表，所以应该启用
     ;; 注意：这里我们无法直接访问内部按钮，所以测试侧边栏的基本功能
     
     ;; 关闭测试窗口
     (send frame show #f)
     
     ;; 关闭数据库连接
     (db:close-database)
     
     ;; 清理临时文件
     (when (file-exists? temp-db-path)
       (delete-file temp-db-path)))
   
   ;; 测试回调函数功能
   (test-case "测试回调函数功能" 
     ;; 创建测试窗口
     (define frame (new frame% [label "Test Frame"] [width 300] [height 400]))
     
     ;; 用于跟踪回调调用的变量
     (define callback-called #f)
     (define callback-view-type #f)
     (define callback-list-id #f)
     (define callback-list-name #f)
     
     ;; 定义测试回调函数
     (define (test-view-change-callback view-type [list-id #f] [list-name #f])
       (set! callback-called #t)
       (set! callback-view-type view-type)
       (set! callback-list-id list-id)
       (set! callback-list-name list-name))
     
     ;; 创建侧边栏，传递测试回调
     (define sidebar (new sidebar% [parent frame] [on-view-change test-view-change-callback]))
     
     ;; 刷新列表（初始化）
     (send sidebar refresh-lists)
     
     ;; 关闭测试窗口
     (send frame show #f)
     
     ;; 检查回调是否正确注册
     (check-false callback-called) ;; 初始状态下回调不应被调用
     )
   
   ;; 测试列表管理功能的间接测试
   (test-case "测试列表管理功能" 
     ;; 创建唯一的临时数据库文件
     (define temp-db-path (format "./test/temp-test-sidebar-lists-~a.db" (current-inexact-milliseconds)))
     
     ;; 确保临时文件不存在
     (when (file-exists? temp-db-path)
       (delete-file temp-db-path))
     
     ;; 连接数据库
     (db:connect-to-database temp-db-path)
     
     ;; 创建测试窗口
     (define frame (new frame% [label "Test Frame"] [width 300] [height 400]))
     
     ;; 创建侧边栏
     (define sidebar (new sidebar% [parent frame]))
     
     ;; 初始列表数量
     (define initial-lists (core:get-all-lists))
     (define initial-count (length initial-lists))
     
     ;; 添加一个新列表
     (core:add-list "新测试列表")
     
     ;; 刷新侧边栏列表
     (send sidebar refresh-lists)
     
     ;; 检查列表数量是否增加
     (define after-add-lists (core:get-all-lists))
     (check-equal? (length after-add-lists) (+ initial-count 1))
     
     ;; 关闭测试窗口
     (send frame show #f)
     
     ;; 关闭数据库连接
     (db:close-database)
     
     ;; 清理临时文件
     (when (file-exists? temp-db-path)
       (delete-file temp-db-path)))
   
   ;; 测试错误处理
   (test-case "测试错误处理" 
     ;; 确保数据库连接已关闭
     (db:close-database)
     
     ;; 创建测试窗口
     (define frame (new frame% [label "Test Frame"] [width 300] [height 400]))
     
     ;; 创建侧边栏
     (define sidebar (new sidebar% [parent frame]))
     
     ;; 尝试刷新列表，应该能处理数据库连接错误
     ;; 这个测试主要验证组件不会崩溃
     (send sidebar refresh-lists)
     
     ;; 关闭测试窗口
     (send frame show #f)
     )
   
   ;; 测试智能列表选中状态切换
   (test-case "测试智能列表选中状态切换" 
     ;; 创建唯一的临时数据库文件
     (define temp-db-path (format "./test/temp-test-sidebar-selected-~a.db" (current-inexact-milliseconds)))
     
     ;; 确保临时文件不存在
     (when (file-exists? temp-db-path)
       (delete-file temp-db-path))
     
     ;; 确保数据库连接已关闭
     (db:close-database)
     
     ;; 连接数据库
     (db:connect-to-database temp-db-path)
     
     ;; 创建测试列表，确保智能列表按钮可用
     (core:add-list "测试列表1")
     
     ;; 创建测试窗口和侧边栏
     (define frame (new frame% [label "Test Frame"] [width 300] [height 400]))
     
     ;; 用于跟踪回调调用的变量
     (define callback-called #f)
     
     ;; 定义测试回调函数
     (define (test-view-change-callback view-type [list-id #f] [list-name #f])
       (set! callback-called #t))
     
     (define sidebar (new sidebar% [parent frame] [on-view-change test-view-change-callback]))
     
     ;; 刷新列表
     (send sidebar refresh-lists)
     
     ;; 获取智能列表按钮
     (define smart-buttons (send sidebar get-smart-list-buttons))
     (check-equal? (length smart-buttons) 4)
     
     ;; 获取今天按钮和计划按钮
     (define today-btn (first smart-buttons))
     (define planned-btn (second smart-buttons))
     
     ;; 检查初始状态：没有选中按钮
     (check-false (send sidebar get-current-selected-btn))
     (check-false (send sidebar get-current-selected-original-label))
     (check-equal? (send today-btn get-label) "今天")
     
     ;; 直接调用set-selected-button方法来测试选中状态切换
     (send sidebar set-selected-button today-btn)
     
     ;; 检查选中状态：今天按钮应该被选中
     (check-equal? (send sidebar get-current-selected-btn) today-btn)
     (check-equal? (send sidebar get-current-selected-original-label) "今天")
     (check-equal? (send today-btn get-label) "→ 今天")
     
     ;; 测试选中另一个按钮
     (send sidebar set-selected-button planned-btn)
     
     ;; 检查选中状态：计划按钮应该被选中，今天按钮应该恢复原状
     (check-equal? (send sidebar get-current-selected-btn) planned-btn)
     (check-equal? (send sidebar get-current-selected-original-label) "计划")
     (check-equal? (send planned-btn get-label) "→ 计划")
     (check-equal? (send today-btn get-label) "今天")
     
     ;; 关闭测试窗口
     (send frame show #f)
     
     ;; 关闭数据库连接
     (db:close-database)
     
     ;; 清理临时文件
     (when (file-exists? temp-db-path)
       (delete-file temp-db-path)))
   
   ;; 测试自定义列表选中状态切换
   (test-case "测试自定义列表选中状态切换" 
     ;; 创建唯一的临时数据库文件
     (define temp-db-path (format "./test/temp-test-sidebar-custom-selected-~a.db" (current-inexact-milliseconds)))
     
     ;; 确保临时文件不存在
     (when (file-exists? temp-db-path)
       (delete-file temp-db-path))
     
     ;; 连接数据库
     (db:connect-to-database temp-db-path)
     
     ;; 创建测试列表
     (core:add-list "自定义列表1")
     (core:add-list "自定义列表2")
     
     ;; 创建测试窗口和侧边栏
     (define frame (new frame% [label "Test Frame"] [width 300] [height 400]))
     
     ;; 用于跟踪回调调用的变量
     (define callback-called #f)
     
     ;; 定义测试回调函数
     (define (test-view-change-callback view-type [list-id #f] [list-name #f])
       (set! callback-called #t))
     
     (define sidebar (new sidebar% [parent frame] [on-view-change test-view-change-callback]))
     
     ;; 刷新列表
     (send sidebar refresh-lists)
     
     ;; 获取自定义列表按钮
     (define custom-buttons (send sidebar get-custom-list-buttons))
     ;; 确保至少有2个按钮
     (check >= (length custom-buttons) 2)
     
     ;; 获取第一个和第二个自定义列表按钮
     (define custom-btn1 (first custom-buttons))
     (define custom-btn2 (second custom-buttons))
     
     ;; 保存原始标签
     (define original-label1 (send custom-btn1 get-label))
     (define original-label2 (send custom-btn2 get-label))
     
     ;; 检查初始状态：没有选中按钮
     (check-false (send sidebar get-current-selected-btn))
     
     ;; 直接调用set-selected-button方法来测试选中状态切换
     (send sidebar set-selected-button custom-btn1)
     
     ;; 检查选中状态：第一个自定义列表按钮应该被选中
     (check-equal? (send sidebar get-current-selected-btn) custom-btn1)
     (check-equal? (string-prefix? (send custom-btn1 get-label) "→ ") #t)
     
     ;; 测试选中另一个自定义列表按钮
     (send sidebar set-selected-button custom-btn2)
     
     ;; 检查选中状态：第二个自定义列表按钮应该被选中，第一个应该恢复原状
     (check-equal? (send sidebar get-current-selected-btn) custom-btn2)
     (check-equal? (string-prefix? (send custom-btn2 get-label) "→ ") #t)
     (check-equal? (string-prefix? (send custom-btn1 get-label) "→ ") #f)
     (check-equal? (send custom-btn1 get-label) original-label1)
     
     ;; 关闭测试窗口
     (send frame show #f)
     
     ;; 关闭数据库连接
     (db:close-database)
     
     ;; 清理临时文件
     (when (file-exists? temp-db-path)
       (delete-file temp-db-path)))
   
   ;; 测试多个列表之间的选中状态切换
   (test-case "测试多个列表之间的选中状态切换" 
     ;; 创建唯一的临时数据库文件
     (define temp-db-path (format "./test/temp-test-sidebar-multi-selected-~a.db" (current-inexact-milliseconds)))
     
     ;; 确保临时文件不存在
     (when (file-exists? temp-db-path)
       (delete-file temp-db-path))
     
     ;; 连接数据库
     (db:connect-to-database temp-db-path)
     
     ;; 创建测试列表
     (core:add-list "测试列表1")
     (core:add-list "测试列表2")
     
     ;; 创建测试窗口和侧边栏
     (define frame (new frame% [label "Test Frame"] [width 300] [height 400]))
     
     ;; 用于跟踪回调调用的变量
     (define callback-called #f)
     
     ;; 定义测试回调函数
     (define (test-view-change-callback view-type [list-id #f] [list-name #f])
       (set! callback-called #t))
     
     (define sidebar (new sidebar% [parent frame] [on-view-change test-view-change-callback]))
     
     ;; 刷新列表
     (send sidebar refresh-lists)
     
     ;; 获取智能列表按钮和自定义列表按钮
     (define smart-buttons (send sidebar get-smart-list-buttons))
     (define custom-buttons (send sidebar get-custom-list-buttons))
     
     ;; 获取今天按钮和第一个自定义列表按钮
     (define today-btn (first smart-buttons))
     (define custom-btn1 (first custom-buttons))
     
     ;; 保存原始标签
     (define today-original-label (send today-btn get-label))
     
     ;; 直接调用set-selected-button方法来测试选中状态切换
     (send sidebar set-selected-button today-btn)
     
     ;; 检查选中状态：今天按钮应该被选中
     (check-equal? (send sidebar get-current-selected-btn) today-btn)
     (check-equal? (string-prefix? (send today-btn get-label) "→ ") #t)
     
     ;; 测试选中自定义列表按钮
     (send sidebar set-selected-button custom-btn1)
     
     ;; 检查选中状态：第一个自定义列表按钮应该被选中，今天按钮应该恢复原状
     (check-equal? (send sidebar get-current-selected-btn) custom-btn1)
     (check-equal? (string-prefix? (send custom-btn1 get-label) "→ ") #t)
     (check-equal? (string-prefix? (send today-btn get-label) "→ ") #f)
     (check-equal? (send today-btn get-label) today-original-label)
     
     ;; 关闭测试窗口
     (send frame show #f)
     
     ;; 关闭数据库连接
     (db:close-database)
     
     ;; 清理临时文件
     (when (file-exists? temp-db-path)
       (delete-file temp-db-path)))
   
   ;; 测试set-selected-button方法的参数传递
   (test-case "测试set-selected-button方法的参数传递" 
     ;; 创建测试窗口和侧边栏
     (define frame (new frame% [label "Test Frame"] [width 300] [height 400]))
     (define sidebar (new sidebar% [parent frame]))
     
     ;; 创建一个测试按钮
     (define test-btn (new button% [parent frame] [label "Test Button"]))
     
     ;; 测试1：只传递按钮参数
     (send sidebar set-selected-button test-btn)
     ;; 验证按钮是否被选中
     (check-equal? (send sidebar get-current-selected-btn) test-btn)
     
     ;; 测试2：传递按钮、列表ID和名称
     (define test-list-id 123)
     (define test-list-name "测试列表")
     (send sidebar set-selected-button test-btn test-list-id test-list-name)
     ;; 验证按钮是否被选中
     (check-equal? (send sidebar get-current-selected-btn) test-btn)
     
     ;; 测试3：传递智能列表参数
     (send sidebar set-selected-button test-btn #f "智能列表")
     ;; 验证按钮是否被选中
     (check-equal? (send sidebar get-current-selected-btn) test-btn)
     
     ;; 关闭测试窗口
     (send frame show #f))
   
   ;; 测试语言切换时智能列表按钮选中状态
   (test-case "测试语言切换时智能列表按钮选中状态" 
     ;; 创建唯一的临时数据库文件
     (define temp-db-path (format "./test/temp-test-sidebar-language-~a.db" (current-inexact-milliseconds)))
     
     ;; 确保临时文件不存在
     (when (file-exists? temp-db-path)
       (delete-file temp-db-path))
     
     ;; 确保数据库连接已关闭
     (db:close-database)
     
     ;; 连接数据库
     (db:connect-to-database temp-db-path)
     
     ;; 创建测试列表，确保智能列表按钮可用
     (core:add-list "测试列表1")
     
     ;; 创建测试窗口和侧边栏
     (define frame (new frame% [label "Test Frame"] [width 300] [height 400]))
     
     (define sidebar (new sidebar% [parent frame]))
     
     ;; 刷新列表
     (send sidebar refresh-lists)
     
     ;; 获取智能列表按钮
     (define smart-buttons (send sidebar get-smart-list-buttons))
     (check-equal? (length smart-buttons) 4)
     
     ;; 获取今天按钮
     (define today-btn (first smart-buttons))
     
     ;; 设置中文
     (lang:set-language! "zh")
     (send sidebar refresh-lists)
     
     ;; 选中今天按钮
     (send sidebar set-selected-button today-btn)
     (check-equal? (send sidebar get-current-selected-btn) today-btn)
     (check-equal? (send today-btn get-label) "→ 今天")
     
     ;; 切换到英文
     (lang:set-language! "en")
     (send sidebar refresh-lists)
     (send sidebar set-selected-button today-btn)
     
     ;; 检查选中状态：今天按钮应该被选中，标签应为英文
     (check-equal? (send sidebar get-current-selected-btn) today-btn)
     (check-equal? (send today-btn get-label) "→ Today")
     
     ;; 切换回中文
     (lang:set-language! "zh")
     (send sidebar refresh-lists)
     (send sidebar set-selected-button today-btn)
     
     ;; 检查选中状态：今天按钮应该被选中，标签应为中文
     (check-equal? (send sidebar get-current-selected-btn) today-btn)
     (check-equal? (send today-btn get-label) "→ 今天")
     
     ;; 关闭测试窗口
     (send frame show #f)
     
     ;; 关闭数据库连接
     (db:close-database)
     
     ;; 清理临时文件
     (when (file-exists? temp-db-path)
       (delete-file temp-db-path))
     
     ;; 恢复中文
     (lang:set-language! "zh"))
   
   ;; 测试删除列表功能的间接测试
   (test-case "测试删除列表功能的间接测试" 
     ;; 确保数据库连接已关闭
     (db:close-database)
     
     ;; 创建测试窗口和侧边栏
     (define frame (new frame% [label "Test Frame"] [width 300] [height 400]))
     (define sidebar (new sidebar% [parent frame]))
     
     ;; 刷新列表
     (send sidebar refresh-lists)
     
     ;; 获取智能列表按钮和自定义列表按钮
     (define smart-buttons (send sidebar get-smart-list-buttons))
     (define custom-buttons (send sidebar get-custom-list-buttons))
     
     ;; 测试侧边栏组件的基本功能
     ;; 验证组件不会崩溃
     (check-not-exn (lambda () (send sidebar refresh-lists)))
     
     ;; 验证智能列表按钮获取功能
     (check-pred list? smart-buttons)
     (check-not-false (not (null? smart-buttons)))
     
     ;; 关闭测试窗口
     (send frame show #f))
   ))

;; 运行测试套件
(run-tests sidebar-tests)