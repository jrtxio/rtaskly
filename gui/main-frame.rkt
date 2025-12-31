#lang racket/gui

(require "sidebar.rkt"
         "task-panel.rkt")

;; 主窗口类
(define main-frame% 
  (class frame% 
    (init [db-path #f])
    (super-new [label "Taskly"]
               [min-width 850]
               [min-height 650])
    
    ;; 全局状态
    (define current-view (make-parameter "list")) ; "list", "today", "planned", "all", "completed"
    (define current-list-id (make-parameter #f))
    (define current-list-name (make-parameter ""))
    
    ;; 创建主面板
    (define main-panel (new horizontal-panel% 
                            [parent this] 
                            [spacing 0] 
                            [border 0]))
    
    ;; 创建侧边栏
    (define sidebar (new sidebar% 
                         [parent main-panel]
                         [on-view-change (lambda (view-type [list-id #f] [list-name #f])
                                           (current-view view-type)
                                           (when list-id (current-list-id list-id))
                                           (when list-name (current-list-name list-name))
                                           (send task-panel update-tasks view-type list-id list-name))]
                         [on-task-updated (lambda ()
                                            (send task-panel update-tasks (current-view) (current-list-id) (current-list-name)))]))
    
    ;; 创建分隔线
    (define divider (new canvas% 
                         [parent main-panel]
                         [min-width 1]
                         [stretchable-width #f]
                         [stretchable-height #t]
                         [paint-callback
                          (lambda (canvas dc)
                            (define-values (w h) (send canvas get-size))
                            (send dc set-pen (make-object color% 209 209 214) 1 'solid)
                            (send dc draw-line 0 0 0 h))]))
    
    ;; 创建任务面板
    (define task-panel (new task-panel% 
                            [parent main-panel]
                            [on-task-updated (lambda ()
                                               (send sidebar refresh-lists)
                                               (send task-panel update-tasks (current-view) (current-list-id) (current-list-name)))]))
    
    ;; 初始化应用
    (define/public (init-app)
      (send sidebar refresh-lists)
      (send task-panel update-tasks (current-view) (current-list-id) (current-list-name)))
    
    ;; 暴露一些方法供外部调用
    (define/public (get-current-view) (current-view))
    (define/public (get-current-list-id) (current-list-id))
    (define/public (get-current-list-name) (current-list-name))
    
    (void)))

(provide main-frame%)
