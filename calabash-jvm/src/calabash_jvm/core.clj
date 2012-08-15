(ns calabash-jvm.core
  (:require [clojure.data.json :as json]
            [clojure.tools.logging :as lg]
            [calabash-jvm.http :as http]
            [clj-logging-config.log4j :as l4j]
            [calabash-jvm.env :as env]))


;; The key is to start swank from emacs as the inferior lisp process instead of calling lein swank from the shell. One way to do this is to use elein (the command is M-x elein-swank). Then you can either inspect the output in the inferior lisp buffer (which is called *elein-swank* in the example of using elein), or execute slime-redirect-inferior-output and have the output inline in the repl. Clojure.contrib.logging is a useful tool for sending log output.


(defn query*
  "qwe"
  [q & selectors]
  (apply http/cmap q :query selectors))

(comment
  (query*
   [:UILabel {:text "Karl Krukow"} :parent :UITableViewCell :child :UITableViewCellReorderControl])

  (query*
   `[UITableView {marked "Karl Krukow"}]
    `[delegate [tableView: self numberOfRowsInSection 0]])
  )

(defmacro query
  "docs"
  [q selectors]
  (apply query* q (transform selectors)))


(comment
  (query
   [UILabel {text "Karl Krukow"}
    parent UITableViewCell
    child UITableViewCellReorderControl])

  (query*
   `[UITableView {marked "Karl Krukow"}]
    `[delegate [tableView self numberOfRowsInSection 0]])
  )
;query*
 []


(http/cmap `[UILabel {text "Cell 2"} parent UITableViewCell child UITableViewCellReorderControl] :query)

(http/cmap `[UITableView] :query :delegate [{:tableView nil} {:numberOfRowsInSection 0}])
;(query [:tableViewCell {:text 42} :parent] :delegate [:tableView self :numberOfRowsInSection 0])

;;Model 2

;{:isa? tableView}

(comment
  list of
  :direction (:parent :child :descendant :ancestor :sibling)
  :filter
  (
   #{UITableView}
   {:text "Karl Krukow"} ;simple selector
   {:marked "Asdf"} ;;accessibility filter
   [[{:tableView nil} {:numberOfRowsInSection 42}] 'result] ;;complex selector
   [:text BEGINSWITH "Karl Krukow"] ;simple relation
     [[{:tableView nil} {:numberOfRowsInSection 42}] BEGINSWITH 'result];complex relation
  )

  (comment simple
       UITableViewCell ;; simple class inclusion
       {:text 42 :marked "ASDF"} ;; conjunction, equality
       [:text 42] ;; selector equality
       [:text LIKE "Cell 1%"] ;; relation/NSPredicate
       UIWebView
       {:css "asdf"})

  (co,,emt simple message send)
  (query UITableView [delegate [tableView :self ]])
Examples

(query `UITableViewCell
       (marked x)
       :parent )
  )






(comment (defmacro query
           ""
           [q & args]
           (let [normal (clojure.walk/prewalk
                         (fn [x]
                           (cond
                             (symbol? x) x
                             (map? x)
                             (let [k (first (keys x))
                                   v (first (vals x))]
                               (str key ":" ))

                             )
                           ))

                 x (apply str (map str (interpose " " q)))]
             `(let [qq# ~x]
                (swank.core/break)
                (query* qq# ~@args)))))
