#lang racket/gui

;; Language management module

(require ffi/unsafe ffi/unsafe/define
         "../utils/path.rkt")

(provide current-language
         set-language!
         translate
         get-language-options
         save-language-setting
         load-language-setting
         get-system-language)

;; Current language parameter - supports "zh" and "en"
(define current-language (make-parameter "zh"))

;; Get system default language (cross-platform implementation)
(define (get-system-language)
  (case (system-type)
    [(windows)  ;; Windows platform - use API call
     (define kernel32 (ffi-lib "kernel32"))
     (define GetUserDefaultUILanguage (get-ffi-obj "GetUserDefaultUILanguage" kernel32 (_fun -> _uint)))
     (define id (GetUserDefaultUILanguage))
     (cond
       [(= id #x0804) "zh"]  ;; Chinese (China)
       [(= id #x0409) "en"]  ;; English (US)
       [else "en"])]  ;; Default to English
    [(macosx)  ;; macOS platform - use environment variable or default
     (let ([lang (getenv "LANG")])
       (if (and lang (regexp-match? #rx"^zh" lang))
           "zh"
           "en"))]
    [else  ;; Other platforms - default to English
     "en"]))

;; Language mapping table
(define translations
  (hash
   ;; Main frame
   "Taskly" (hash "zh" "Taskly" "en" "Taskly")
   "文件" (hash "zh" "文件" "en" "File")
   "新建数据库" (hash "zh" "新建数据库" "en" "New Database")
   "打开数据库" (hash "zh" "打开数据库" "en" "Open Database")
   "关闭数据库" (hash "zh" "关闭数据库" "en" "Close Database")
   "退出" (hash "zh" "退出" "en" "Exit")
   "帮助" (hash "zh" "帮助" "en" "Help")
   "关于" (hash "zh" "关于" "en" "About")
   "就绪" (hash "zh" "就绪" "en" "Ready")
   "已切换到\"~a\"视图" (hash "zh" "已切换到\"~a\"视图" "en" "Switched to \"~a\" view")
   "数据库连接成功" (hash "zh" "数据库连接成功" "en" "Database connected successfully")
   "数据库已关闭" (hash "zh" "数据库已关闭" "en" "Database closed")
   
   ;; New database dialog
   "新建数据库文件" (hash "zh" "新建数据库文件" "en" "New Database File")
   "请输入新数据库文件的路径和名称。" (hash "zh" "请输入新数据库文件的路径和名称。" "en" "Please enter the path and name for the new database file.")
   "浏览..." (hash "zh" "浏览..." "en" "Browse...")
   "保存数据库文件" (hash "zh" "保存数据库文件" "en" "Save Database File")
   "确定" (hash "zh" "确定" "en" "OK")
   "取消" (hash "zh" "取消" "en" "Cancel")
   
   ;; Open database dialog
   "选择数据库文件" (hash "zh" "选择数据库文件" "en" "Select Database File")
   
   ;; About dialog
   "关于 Taskly" (hash "zh" "关于 Taskly" "en" "About Taskly")
   "V1.0.0" (hash "zh" "V1.0.0" "en" "V1.0.0")
   "极简本地任务管理工具" (hash "zh" "极简本地任务管理工具" "en" "Minimalist Local Task Management Tool")
   "完全本地化，用户掌控数据" (hash "zh" "完全本地化，用户掌控数据" "en" "Fully Localized, User Controls Data")
   
   ;; Sidebar
   "今天" (hash "zh" "今天" "en" "Today")
   "计划" (hash "zh" "计划" "en" "Planned")
   "全部" (hash "zh" "全部" "en" "All")
   "完成" (hash "zh" "完成" "en" "Completed")
   "我的列表" (hash "zh" "我的列表" "en" "My Lists")
   "添加新列表" (hash "zh" "添加新列表" "en" "Add New List")
   "列表名称:" (hash "zh" "列表名称:" "en" "List Name:")
   "删除列表" (hash "zh" "删除列表" "en" "Delete List")
   "选择要删除的列表:" (hash "zh" "选择要删除的列表:" "en" "Select a list to delete:")
   "确认删除" (hash "zh" "确认删除" "en" "Confirm Delete")
   "确定要删除列表\"~a\"及其所有任务吗？" (hash "zh" "确定要删除列表\"~a\"及其所有任务吗？" "en" "Are you sure you want to delete the list \"~a\" and all its tasks?")
   "是" (hash "zh" "是" "en" "Yes")
   "否" (hash "zh" "否" "en" "No")
   "删除" (hash "zh" "删除" "en" "Delete")
   
   ;; Task panel
   "欢迎使用 Taskly！" (hash "zh" "欢迎使用 Taskly！" "en" "Welcome to Taskly!")
   "欢迎来到 Taskly" (hash "zh" "欢迎来到 Taskly" "en" "Welcome to Taskly")
   "请选择或创建任务数据库" (hash "zh" "请选择或创建任务数据库" "en" "Please select or create a task database")
   "请创建或打开数据库文件以开始使用" (hash "zh" "请创建或打开数据库文件以开始使用" "en" "Please create or open a database file to get started")
   "操作指南：" (hash "zh" "操作指南：" "en" "Quick Start Guide:")
   "1. 点击  文件 → 新建数据库  创建新的任务数据库" (hash "zh" "1. 点击  文件 → 新建数据库  创建新的任务数据库" "en" "1. Click File → New Database to create a new task database")
   "2. 或点击  文件 → 打开数据库  使用现有数据库" (hash "zh" "2. 或点击  文件 → 打开数据库  使用现有数据库" "en" "2. Or click File → Open Database to use an existing database")
   "搜索结果: \"~a\"" (hash "zh" "搜索结果: \"~a\"" "en" "Search Results: \"~a\"")
   "搜索结果" (hash "zh" "搜索结果" "en" "Search Results")
   "编辑" (hash "zh" "编辑" "en" "Edit")
   "低" (hash "zh" "低" "en" "Low")
   "中" (hash "zh" "中" "en" "Medium")
   "高" (hash "zh" "高" "en" "High")
   "确认删除" (hash "zh" "确认删除" "en" "Confirm Delete")
   "确定要删除任务\"~a\"吗？" (hash "zh" "确定要删除任务\"~a\"吗？" "en" "Are you sure you want to delete the task \"~a\"?")
   
   ;; Add/edit task dialog
   "添加新任务" (hash "zh" "添加新任务" "en" "Add New Task")
   "编辑任务" (hash "zh" "编辑任务" "en" "Edit Task")
   "任务描述:" (hash "zh" "任务描述:" "en" "Task Description:")
   "截止日期 (可选):" (hash "zh" "截止日期 (可选):" "en" "Due Date (Optional):")
   "优先级:" (hash "zh" "优先级:" "en" "Priority:")
   "任务列表:" (hash "zh" "任务列表:" "en" "Task List:")
   "日期格式错误" (hash "zh" "日期格式错误" "en" "Invalid Date Format")
   "请输入正确的日期格式，例如: +1d, @10am, 2025-08-07" (hash "zh" "请输入正确的日期格式，例如: +1d, @10am, 2025-08-07" "en" "Please enter a valid date format, e.g.: +1d, @10am, 2025-08-07")
   
   ;; Settings menu
   "设置" (hash "zh" "设置" "en" "Settings")
   "语言" (hash "zh" "语言" "en" "Language")
   "中文" (hash "zh" "中文" "en" "Chinese")
   "English" (hash "zh" "English" "en" "English")
   ))

;; Translation function
(define (translate key . args)
  (define lang (current-language))
  (define translation (hash-ref (hash-ref translations key (hash "zh" key "en" key)) lang key))
  (apply format translation args))

;; Set language
(define (set-language! lang)
  (when (or (equal? lang "zh") (equal? lang "en"))
    (current-language lang)))

;; Get language options
(define (get-language-options)
  (list (cons "zh" (translate "中文"))
        (cons "en" (translate "English"))))

;; Save language setting
(define (save-language-setting)
  (set-config "language" (current-language)))

;; Load language setting
(define (load-language-setting)
  (let ((lang (get-config "language" #f)))
    (if lang
        (set-language! lang)
        (set-language! (get-system-language)))))
