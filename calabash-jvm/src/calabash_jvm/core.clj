(ns calabash-jvm.core
  (:require [clojure.data.json :as json]
            [clojure.tools.logging :as lg]
            [calabash-jvm.http :as http]
            [clj-logging-config.log4j :as l4j]
            [calabash-jvm.env :as env]
            [calabash-jvm.events :as events]))



(defn- dsl-op
  [key val]
  {::_calabash-type key key val})

(defn index
  "construct an index query"
  [i]
  (dsl-op :index i))

(defn css
  "construct a css query for web views"
  [css]
  (dsl-op :css css))

(defn xpath
  "construct a css query for web views"
  [xpath]
  (dsl-op :xpath xpath))


(defn query*
  "query views and optionally apply selectors to the results"
  [q & selectors]
  (apply http/map-views  q :query selectors))

(defn playback
  ([recname] (events/playback-or-nil recname {}))
  ([recname options] (events/playback-or-nil recname options)))

(defn touch
  "touch the center of the view that results from performing query q.
   Options include offset")

(comment
  (query*
   [:UILabel {:text "Karl Krukow"} :parent :UITableViewCell :child :UITableViewCellReorderControl])

  (query*
   `[UITableView {marked "Karl Krukow"}]
    `[delegate [tableView :self numberOfRowsInSection 0]])
  )

(comment
  (defmacro query
    "docs"
    [q selectors]
    (apply query* q (transform selectors))))


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

(comment
  []


  (http/cmap `[UILabel {text "Cell 2"} parent UITableViewCell child UITableViewCellReorderControl] :query)

  (http/cmap `[UITableView] :query :delegate [{:tableView nil} {:numberOfRowsInSection 0}]))
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


  (comment simple message send
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
                  (query* qq# ~@args))))))
