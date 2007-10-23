
(in-package :weblocks)

(export '(datagrid datagrid-data-class datagrid-data
	  datagrid-render-item-ops-bar
	  datagrid-render-pagination-widget datagrid-sort
	  datagrid-allow-sorting datagrid-forbid-sorting-on
	  datagrid-search datagrid-allow-searching-p
	  datagrid-pagination-widget datagrid-allow-pagination-p
	  datagrid-show-total-items-count-p datagrid-selection
	  datagrid-allow-select-p datagrid-item-ops
	  datagrid-allow-item-ops-p datagrid-allow-drilldown-p
	  datagrid-on-drilldown datagrid-drilled-down-item
	  datagrid-autoset-drilled-down-item-p datagrid-flash
	  datagrid-data datagrid-data-count
	  render-datagrid-table-body))

(defwidget datagrid (widget)
  ((data-class :accessor datagrid-data-class
	       :initform nil
	       :initarg :data-class
	       :documentation "The class of the objects rendered by
	       this datagrid. While the class can potentially be
	       obtained from the data directly, it is not always
	       possible. Additionally, specifying the class makes
	       datagrid more efficient. For these reasons it is
	       required to specify this slot at the instantiation
	       time.")
   (data :accessor datagrid-data
	 :initform nil
	 :initarg :data
	 :documentation "Either a sequence of data objects that will
	 be rendered and modified by this widget, or a function
	 designator that accepts searching, sorting, and pagination
	 parameters. If this slot is bound to a sequence, datagrid
	 will do the pagination and sorting itself in memory
	 destructively. If the slot is bound to a function (or a
	 symbol that designates a function), the function is expected
	 to return a properly sorted and paged sequence. The function
	 should also accept a :countp keyword argument. If true, the
	 function should return only the number of items with the
	 given search parameters, not the actual items themselves.")
   (sort :accessor datagrid-sort
	 :initform nil
	 :initarg :sort
	 :documentation "Holds a dotted pair of a path to the sorted
         column and the direction of the sort (:ascending
         or :descending).")
   (allow-sorting :accessor datagrid-allow-sorting
		  :initform t
		  :initarg :allow-sorting
		  :documentation "This slot controls whether the
		  datagrid object should support sorting. If set to
		  t (default), sorting is allowed; if set to nil
		  sorting is disallowed. If set to a list of slot
		  names, only these slots will be available for the
		  user to sort on.")
   (forbid-sorting-on :accessor datagrid-forbid-sorting-on
		      :initform nil
		      :initarg :forbid-sorting-on
		      :documentation "A list of slot names on which
		      datagrid will not do sorting. Note, this slot
		      takes precedence over 'allow-sorting'.")
   (search :accessor datagrid-search
	   :initform nil
	   :initarg :search
	   :affects-dirty-status-p nil
	   :documentation "Contains a search string that will filter
	   results. Initially set to nil, which means all results will
	   be visible.")
   (allow-searching-p :accessor datagrid-allow-searching-p
		      :initform t
		      :initarg :allow-searching-p
		      :documentation "Set to true to enable searching,
		      or to nil to disable it.")
   (pagination-widget :accessor datagrid-pagination-widget
		      :initform nil
		      :initarg :pagination-widget
		      :documentation "An instance of a pagination
		      widget used by the datagrid to manage data
		      pagination.")
   (allow-pagination-p :accessor datagrid-allow-pagination-p
		       :initform t
		       :initarg :allow-pagination-p
		       :documentation "Set to true to enable
		       pagination (default) or nil to disable it.")
   (search-pagination-history :accessor datagrid-search-pagination-history
			      :initform nil
			      :affects-dirty-status-p nil
			      :documentation "When the user searches
			      the datagrid, the current page is stored
			      in this slot, to be restored when the
			      user clears the search.")
   (show-total-items-count-p :accessor datagrid-show-total-items-count-p
			     :initform t
			     :initarg :show-total-items-count-p
			     :documentation "If set to true (the
			     default), the datagrid displays a message
			     specifying how many items are visible. If
			     searching is enabled, the message
			     specifies how many items have been hidden
			     by the search.")
   (selection :accessor datagrid-selection
	      :initform (cons :none nil)
	      :initarg :selection
	      :affects-dirty-status-p nil
	      :documentation "Contains a cons cell that identifies
	      currently selected elements. That 'car' of the cell is
	      either :all or :none. In case of :all, all items except
	      the ones in the cdr list are selected. In case of :none,
	      none of the elements except the ones in the cdr list are
	      selected.")
   (allow-select-p :accessor datagrid-allow-select-p
		   :initform nil
		   :initarg :allow-select-p
		   :documentation "If true, datagrid provides the UI
		   to select entries in the collection.")
   (item-ops :accessor datagrid-item-ops
	     :initform nil
	     :initarg :item-ops
	     :documentation "A list of cons cells that define
	     operations on items. A car of each cell should contain a
	     name of the operation, while the cdr of each cell should
	     contain a function that accepts two arguments - the grid
	     object, and the selection cons cell passed to the
	     function for convenience. Any given function is called by
	     the datagrid when the appropriate operation has been
	     invoked by the user.")
   (allow-item-ops-p :accessor datagrid-allow-item-ops-p
		     :initform t
		     :initarg :allow-item-ops-p
		     :documentation "If true, datagrid provides UI to
		     access operations defined in 'item-ops'.")
   (on-drilldown :accessor datagrid-on-drilldown
		 :initform nil
		 :initarg :on-drilldown
		 :documentation "A cons cell that represents a
	         drilldown operation. The car of the cell should
	         contain symbol representing the name of the
	         operation (i.e. 'details', 'edit', etc.) and the cdr
	         of the cell should contain a function of two
	         arguments (grid obj and item object). If this slot
	         isn't set to nill and 'allow-drilldown-p' is true,
	         datagrid provides the UI to drill down into items.")
   (allow-drilldown-p :accessor datagrid-allow-drilldown-p
		      :initform t
		      :initarg :allow-drilldown-p
		      :documentation "If set to true and
		      'on-drilldown' isn't nil, datagrid provides the
		      UI to drill down into items.")
   (drilled-down-item :accessor datagrid-drilled-down-item
		      :initform nil
		      :initarg :drilled-down-item
		      :documentation "If 'allow-drilldown-p' is set
		      to true and the user drills down on an item this
		      slot can be set to the item in question. The
		      datagrid will then render the appropriate row
		      with a 'drilled-down' class for CSS
		      styling. This slot is set to the drilled down
		      item automatically only when
		      'autoset-drilled-down-item-p' is true. Note, it
		      is always the responsibility of the datagrid's
		      client to reset this slot back to nil.")
   (autoset-drilled-down-item-p :accessor datagrid-autoset-drilled-down-item-p
				:initform nil
				:initarg :autoset-drilled-down-item-p
				:documentation "If set to true,
				'drilled-down-item' will be
				automatically set to the appropriate
				item when the user drills down on the
				grid.")
   (flash :accessor datagrid-flash
	  :initform (make-instance 'flash)
	  :initarg :flash
	  :documentation "A flash widget provided by the datagrid to
	  display relevant information to the user (errors, item
	  modification information, etc.)"))
  (:documentation "Represents a sortable, pagable table. This
  widget is inspired by ASP.NET's datagrid control."))

;;; Ensure that data-class is specified and that we cannot sort on the
;;; "select" slot. Additionally, ensure pagination widget exists.
(defmethod initialize-instance :after ((obj datagrid) &rest initargs &key &allow-other-keys)
  (unless (datagrid-pagination-widget obj)
    (setf (datagrid-pagination-widget obj)
	  (make-instance 'pagination
			 :on-change (lambda (&rest args)
				      (datagrid-clear-selection obj)
				      (mark-dirty obj))
			 :on-error (datagrid-flash obj)
			 :show-total-items-p nil
			 :total-items (datagrid-data-count obj :totalp t))))
  (pushnew 'select (datagrid-forbid-sorting-on obj))
  (when (null (datagrid-data-class obj))
    (error "data-class must be specified to initialize a datagrid.")))

;;; If the 'data' slot is a sequence, filters it, sorts the filtered
;;; data, and returns the result. If it is a function, calls it with
;;; appropriate parameters. Signals an error otherwise.
(defmethod datagrid-data ((grid-obj datagrid))
  (with-slots (data) grid-obj
    (multiple-value-bind (begin end)
	(when (datagrid-allow-pagination-p grid-obj)
	  (pagination-page-item-range (datagrid-pagination-widget grid-obj)))
      (etypecase data
	(sequence		 ; 'sequence' also handles null values
	 (let ((dataseq (datagrid-sort-data grid-obj
					    (datagrid-filter-data grid-obj data))))
	   (if (and begin end)
	       (subseq dataseq begin end)
	       dataseq)))
	((or function symbol)
	 (funcall data (datagrid-search grid-obj) (datagrid-sort grid-obj) (cons begin end)))))))

(defun datagrid-data-count (grid &key totalp)
  "Returns the number of items in the grid. This function works
similarly to datagrid-data in principle. Note, if totalp is set to
true, 'datagrid-data-count' returns the the total number of items and
ignores searching parameters."
  (with-slots (data) grid
    (etypecase data
      (sequence ; 'sequence' also handles null values
       (if totalp
	   (length data)
	   (length (datagrid-filter-data grid data))))
      ((or function symbol)
       (funcall data
                (when (not totalp)
                  (datagrid-search grid))
                nil
		nil
                :countp t)))))

(defun append-custom-slots (custom-slots args)
  "Appends 'custom-slots' to whatever custom slots that are already
defined in 'args'."
  (append (cadr (member :custom-slots args))
	  custom-slots))

(defgeneric datagrid-render-item-ops-bar (grid &rest args)
  (:documentation
   "This function is responsible for rendering item-ops bar for the
datagrid. Specialize this function to provide custom item ops bar
rendering."))

(defmethod datagrid-render-item-ops-bar ((grid datagrid) &rest args)
  (when (and (datagrid-allow-item-ops-p grid)
	     (datagrid-item-ops grid))
    (with-html
      (:div :class "item-operations"
	    (mapc (lambda (op)
		    (render-button (car op)))
		  (datagrid-item-ops grid))))))

(defgeneric datagrid-render-pagination-widget (grid &rest args)
  (:documentation
   "This function is responsible for rendering the pagination widget
for the datagrid."))

(defmethod datagrid-render-pagination-widget ((grid datagrid) &rest args)
  (when (datagrid-allow-pagination-p grid)
    (render-widget (datagrid-pagination-widget grid))))

;;; Renders the body of the data grid.
(defmethod render-widget-body ((obj datagrid) &rest args
			       &key pre-data-mining-fn post-data-mining-fn)
   ; Render Data mining
  (safe-funcall pre-data-mining-fn obj)
  (when (>= (datagrid-data-count obj :totalp t) 1)
    (with-html
      (:div :class "data-mining-bar"
	    (when (datagrid-allow-searching-p obj)
	      (apply #'datagrid-render-search-bar obj args))
	    (when (datagrid-allow-select-p obj)
	      (apply #'render-select-bar obj args)))))
  (safe-funcall post-data-mining-fn obj)
  ; Render flash
  (render-widget (datagrid-flash obj))
  ; Render Body
  (let ((action (make-action (lambda (&rest args)
			       (datagrid-clear-selection obj)
			       (loop for i in (request-parameters)
				  when (string-starts-with (car i) "item-")
				  do (datagrid-select-item obj (substring (car i) 5)))
			       (loop for i in (datagrid-item-ops obj)
				  when (member (car i) (request-parameters)
					       :key #'car
					       :test #'string-equal)
				  do (funcall (cdr i) obj (datagrid-selection obj)))
			       (datagrid-clear-selection obj)))))
    (with-html-form (:get action :class "datagrid-form")
      (apply #'render-datagrid-table-body obj args)
      ; Render Item ops
      (apply #'datagrid-render-item-ops-bar obj args)))
  ; Render Pagination
  (datagrid-render-pagination-widget obj))

(defgeneric render-datagrid-table-body (grid &rest args)
  (:documentation
   "Renders the actual data of the datagrid without any controls
before or after. This function is used to update the body during ajax
search requests."))

(defmethod render-datagrid-table-body ((grid datagrid) &rest args)
  (apply #'datagrid-update-sort-column grid args)
  (when (datagrid-allow-pagination-p grid)
    (setf (pagination-total-items (datagrid-pagination-widget grid))
	  (datagrid-data-count grid :totalp nil)))
  (with-html
    (:div :class "datagrid-body"
	  (apply #'render-table (datagrid-data grid)
		 :grid-obj grid
		 :summary (if (datagrid-sort grid)
			      (format nil "Ordered by ~A, ~A."
				      (string-downcase (humanize-name
							(datagrid-sorted-slot-name
							 (datagrid-sort grid))))
				      (string-downcase (humanize-name
							(cdr (datagrid-sort grid)))))
			      nil)
		 :highlight (when (datagrid-search grid)
			      (make-isearch-regex (datagrid-search grid)))
		 :custom-slots (append-custom-slots
				(remove nil
				 (list
				  (when (datagrid-allow-select-p grid)
				    `(0 . (select . ,(curry #'datagrid-render-select-body-cell grid))))
				  (when (and (datagrid-allow-drilldown-p grid)
					     (datagrid-on-drilldown grid))
				    (cons (car (datagrid-on-drilldown grid))
					  (curry #'render-datagrid-drilldown-body-cell grid)))))
				args)
		 args))))

(defmethod (setf datagrid-search) :before (value (obj datagrid))
  (when (and (datagrid-allow-pagination-p obj)
	     (null (datagrid-search obj)))
    (setf (datagrid-search-pagination-history obj)
	  (pagination-current-page (datagrid-pagination-widget obj)))))

(defmethod (setf datagrid-search) :after (value (obj datagrid))
  (when (and (datagrid-allow-pagination-p obj)
	     (null value))
    (setf (pagination-current-page (datagrid-pagination-widget obj))
	  (datagrid-search-pagination-history obj))
    (setf (datagrid-search-pagination-history obj) nil)))

(defmethod widget-public-dependencies ((obj datagrid))
  (append (list (public-file-relative-path :stylesheet "pagination"))
	  (call-next-method)))

