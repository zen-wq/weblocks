(defpackage #:weblocks/widgets/base
  (:use #:cl)
  (:nicknames #:weblocks/widget)
  (:import-from #:weblocks/html
                #:with-html
                #:with-html-string)
  (:import-from #:weblocks/widgets/mop
                #:widget-class)
  (:import-from #:weblocks/dependencies
                #:get-collected-dependencies
                #:get-dependencies
                #:push-dependencies
                #:render-in-ajax-response)
  (:import-from #:weblocks/commands
                #:add-command)
  (:import-from #:weblocks/request
                #:ajax-request-p)
  (:import-from #:weblocks/widgets/dom
                #:dom-id
                #:dom-object-mixin)
  (:import-from #:alexandria
                #:make-keyword)
  (:import-from #:cl-strings
                #:join)

  ;; Just dependencies
  (:import-from #:log)
  
  (:export #:defwidget
           #:render
           #:get-css-classes
           #:get-html-tag
           #:render-widget
           #:mark-dirty
           #:update
           #:widget))
(in-package weblocks/widgets/base)


(defclass widget (dom-object-mixin)
  ((propagate-dirty :accessor widget-propagate-dirty
                    :initform nil
                    :initarg :propagate-dirty
                    :documentation "A list of widgets which will be made
                    dirty when this widget is made dirty via a POST
                    request. This slot allows setting up dependencies
                    between widgets that will make multiple widgets
                    update automatically during AJAX requests.")
   (continuation :accessor widget-continuation
                 :initform nil
                 :documentation "Stores the continuation object for
                 widgets that were invoked via one of the do-*
                 functions ('do-page', etc.). When 'answer' is called
                 on a widget, this value is used to resume the
                 computation."))
  #+lispworks (:optimize-slot-access nil)
  (:metaclass widget-class)
  (:documentation "Base class for all widget objects."))


(defmacro defwidget (name direct-superclasses &body body)
  "A macro used to define new widget classes. Behaves exactly as
defclass, except adds 'widget-class' metaclass specification and
inherits from 'widget' if no direct superclasses are provided."
  `(progn
     (defclass ,name ,(remove-duplicates
                       (or direct-superclasses
                           '(widget)))
       ,@body
       (:metaclass widget-class))))


(defgeneric render (widget)
  (:documentation "Define this method to render widget's content."))


(defmethod render (widget)
  "By default, widget rendered with a text, suggesting to define a rendering method."
  (let ((class-name (class-name (class-of widget))))
    (with-html
      (:p "Please, define:"
          (:pre (format nil
                        "(defmethod weblocks/widget:render ((widget ~a))
    (weblocks/html:with-html
        (:p \"My ~a widget\")))"
                        class-name
                        class-name))))))


;; TODO: REPLACE THIS with render :around
(defun render-widget (widget)
  "This function is intended for internal usage only.
   It renders widget with surrounding HTML tag and attributes."
  (log:debug "Rendering widget" widget "with" (get-collected-dependencies))
  
  (let ((widget-dependencies (get-dependencies widget)))
    ;; Update new-style dependencies
    (push-dependencies widget-dependencies)
    
    (when (ajax-request-p)
      ;; Generate code to embed new dependencies into the page on the fly
      (mapc #'render-in-ajax-response
            widget-dependencies)))
  
  (with-html
    (:tag
     :name (get-html-tag widget)
     :class (get-css-classes-as-string widget)
     :id (dom-id widget)
     ;; TODO: try to remove progn
     (progn (render widget)
            nil))))


(defgeneric get-html-tag (widget)
  (:documentation "This method should return a keyword, like :div or :article.
                   By default, it returns :div"))


(defmethod get-html-tag ((widget t))
  :div)


(defgeneric get-css-classes (widget)
  (:documentation "Returns a list of classes for the widget.
                   Classes may be a strings or a keywords.
                   By default, :widget and keyworded class name are returned.
                   Use (append (list :new-class) (call-next-method))
                   to add new classes."))


(defmethod get-css-classes ((widget t))
  (list :widget
        (make-keyword
         (class-name (class-of widget)))))


(defun get-css-classes-as-string (widget)
  (let* ((classes (get-css-classes widget))
         (stringified (loop for cls in classes
                            collect (etypecase cls
                                      (string cls)
                                      (keyword (string-downcase (symbol-name cls)))))))
    (join stringified :separator " ")))


;; (defgeneric mark-dirty (w &key propagate)
;;   (:documentation
;;    "Default implementation adds a widget to a list of dirty
;; widgets. Normally used during an AJAX request. If there are any
;; widgets in the 'propagate-dirty' slot of 'w' and 'propagate' is true
;; \(the default\), these widgets are added to the dirty list as well.

;; Note that this function is automatically called when widget slots are
;; modified, if slots are marked have affects-dirty-status-p flag.

;; Returns NIL if the widget is already dirty or T and the results
;; of calling MARK-DIRTY on the list of dependents \(propagate-dirty\)."))


;; (defmethod mark-dirty ((w widget) &key (propagate t))
;;   (unless (weblocks:widget-dirty-p w)
;;     (pushnew w weblocks::*dirty-widgets*)
;;     ;; NOTE: we have to check for unbound slots because this function
;;     ;; may get called at initialization time before those slots are bound
;;     (values t (when (and propagate (slot-boundp w 'propagate-dirty))
;;                 (mapc #'mark-dirty
;;                       (remove nil (widget-propagate-dirty w)))))))


(defgeneric update (w &key inserted-after inserted-before)
  (:documentation "This method should be called to update widget on a client.

Usually this required as a result of an action execution.

In old weblocks there was a mark-dirty method. This one replaces it.
To make everything easier, new protocol excludes \"propagation\". If you
need to update other widgets, please define \"update\" method for you widget.
You can use :before or :after modifier, to keep current behavior and to add
propagation code."))


(defmethod update ((w widget) &key inserted-after inserted-before)
  (log:debug "Updating widget" w inserted-after inserted-before)
  (cond
    ((and inserted-after inserted-before)
     (error "Arguments inserted-after and inserted-before can't be used together."))
    (inserted-after (add-command
                     :insert-widget
                     :widget (with-html-string
                               (render-widget w))
                     :after (dom-id inserted-after)))
    (inserted-before (add-command
                      :insert-widget
                      :widget (with-html-string
                                (render-widget w))
                      :before (dom-id inserted-before)))
    (t (add-command
        :update-widget
        :dom-id (dom-id w)
        :widget (with-html-string
                  (render-widget w))))))
