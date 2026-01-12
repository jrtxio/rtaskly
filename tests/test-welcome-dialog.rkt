#lang racket/gui

(require rackunit
         rackunit/text-ui
         (prefix-in gui: racket/gui)
         "../src/taskly.rkt"
         "../src/gui/language.rkt"
         "../src/utils/path.rkt")

;; 定义测试套件
(define welcome-dialog-tests
  (test-suite
   "欢迎窗口测试"
   
   ;; 测试欢迎窗口的基本功能
   (test-case "测试欢迎窗口基本功能" 
     ;; 测试语言加载功能
     (load-language-setting)
     
     ;; 测试翻译功能
     (check-equal? (translate "欢迎来到 Taskly") "欢迎来到 Taskly")
     (check-equal? (translate "请选择或创建任务数据库") "请选择或创建任务数据库")
     (check-equal? (translate "浏览...") "浏览...")
     (check-equal? (translate "确定") "确定")
     (check-equal? (translate "取消") "取消")
     
     ;; 测试英文翻译
     (set-language! "en")
     (check-equal? (translate "欢迎来到 Taskly") "Welcome to Taskly")
     (check-equal? (translate "请选择或创建任务数据库") "Please select or create a task database")
     (check-equal? (translate "浏览...") "Browse...")
     (check-equal? (translate "确定") "OK")
     (check-equal? (translate "取消") "Cancel")
     
     ;; 恢复中文
     (set-language! "zh"))
   
   ;; 测试数据库路径功能
   (test-case "测试数据库路径功能" 
     ;; 测试默认数据库路径
     (check-pred string? (path->string (get-default-db-path))))
   
   ;; 测试窗口参数设置
   (test-case "测试窗口参数设置" 
     ;; 由于窗口需要用户交互，我们只测试窗口的参数设置
     ;; 而不实际显示窗口
     
     ;; 测试语言设置加载
     (load-language-setting)
     
     ;; 测试窗口标题翻译
     (check-equal? (translate "欢迎来到 Taskly") "欢迎来到 Taskly")
     
     ;; 测试提示信息翻译
     (check-equal? (translate "请选择或创建任务数据库") "请选择或创建任务数据库"))
   ))

;; 运行测试套件
(run-tests welcome-dialog-tests)
