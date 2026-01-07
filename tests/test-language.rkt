#lang racket/gui

(require rackunit
         rackunit/text-ui
         "../src/gui/language.rkt")

;; 定义测试套件
(define language-tests
  (test-suite
   "语言管理模块测试"
   
   ;; 测试当前语言参数
   (test-case "测试当前语言参数" 
     ;; 默认语言应该是中文
     (check-equal? (current-language) "zh")
     
     ;; 设置为英文
     (set-language! "en")
     (check-equal? (current-language) "en")
     
     ;; 设置为中文
     (set-language! "zh")
     (check-equal? (current-language) "zh")
     
     ;; 无效语言应该被忽略
     (set-language! "invalid")
     (check-equal? (current-language) "zh"))
   
   ;; 测试翻译函数
   (test-case "测试翻译函数" 
     ;; 测试中文翻译
     (set-language! "zh")
     (check-equal? (translate "今天") "今天")
     (check-equal? (translate "计划") "计划")
     (check-equal? (translate "全部") "全部")
     (check-equal? (translate "完成") "完成")
     (check-equal? (translate "我的列表") "我的列表")
     
     ;; 测试英文翻译
     (set-language! "en")
     (check-equal? (translate "今天") "Today")
     (check-equal? (translate "计划") "Planned")
     (check-equal? (translate "全部") "All")
     (check-equal? (translate "完成") "Completed")
     (check-equal? (translate "我的列表") "My Lists")
     
     ;; 测试带参数的翻译
     (check-equal? (translate "已切换到\"~a\"视图" "Today") "Switched to \"Today\" view")
     (check-equal? (translate "确定要删除列表\"~a\"及其所有任务吗？" "Test List") "Are you sure you want to delete the list \"Test List\" and all its tasks?")
     
     ;; 恢复中文
     (set-language! "zh"))
   
   ;; 测试语言选项获取
   (test-case "测试语言选项获取" 
     ;; 设置为中文
     (set-language! "zh")
     (define options-zh (get-language-options))
     (check-equal? (length options-zh) 2)
     (check-equal? (cdr (first options-zh)) "中文")
     (check-equal? (cdr (second options-zh)) "English")
     
     ;; 设置为英文
     (set-language! "en")
     (define options-en (get-language-options))
     (check-equal? (length options-en) 2)
     (check-equal? (cdr (first options-en)) "Chinese")
     (check-equal? (cdr (second options-en)) "English")
     
     ;; 恢复中文
     (set-language! "zh"))
   
   ;; 测试语言设置的持久化存储
   (test-case "测试语言设置的持久化存储" 
     ;; 保存当前语言
     (set-language! "en")
     (save-language-setting)
     
     ;; 切换到中文
     (set-language! "zh")
     (check-equal? (current-language) "zh")
     
     ;; 加载保存的语言设置
     (load-language-setting)
     (check-equal? (current-language) "en")
     
     ;; 清理：恢复中文
     (set-language! "zh")
     (save-language-setting))
   
   ;; 测试未知键的翻译
   (test-case "测试未知键的翻译" 
     ;; 未知键应该返回键本身
     (set-language! "zh")
     (check-equal? (translate "未知键") "未知键")
     
     (set-language! "en")
     (check-equal? (translate "未知键") "未知键"))
   ))

;; 运行测试套件
(run-tests language-tests)
