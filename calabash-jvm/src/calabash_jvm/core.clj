(ns calabash-jvm.core
  (:require [clojure.data.json :as json]
            [clj-logging-config.log4j :as l4j]
            [calabash-jvm
             [env :as env]
             [events :as events]
             [http :as http]])
  (:use [calabash-jvm.utils :only [logging]])
  (:import [java.io File FileOutputStream]))


(def screenshot-count (atom 0))

(defn screenshot
  [& keyargs]
  (logging
   {:action "screenshot"}
   (let [opts (merge {:prefix (or (env/getenv "SCREENSHOT_PATH") "")
                      :name "screenshot"}
                     (apply hash-map keyargs))
         sc-data (http/req {:method :get
                            :path "screenshot"
                            :as :stream
                            :binary true})
         path (str (:prefix opts) (:name opts) "_" @screenshot-count ".png")]
     (clojure.java.io/copy sc-data (java.io.FileOutputStream. path))
     (swap! screenshot-count inc)
     path)))


(defn query*
  [q & selectors]
  (logging
   {:query q
    :extras selectors
    :action "query*"}
   (apply http/map-views  q :query selectors)))

(defn query-all*
  "query views (optionally applying selectors to results)
   Does not filter out non-visible views"
  [q & selectors]
  (logging
   {:query q
    :extras selectors
    :action "query-all*"}
   (apply http/map-views q :query_all selectors)))


(defn touch*
  "touch the center of the view that results from performing query q.
   Options include offset..."
  ([q] (touch* q {}))
  ([q options]
     (logging
      {:query q
       :extras options
       :action "touch*"}
      (events/playback "touch"
                       (if q
                         (assoc options :query q)
                         options)))))

(defn touch-point
  "Touch the point x,y in the screen coordinate system"
  [x y] (touch* nil {:offset {:x x :y y}}))

(defn touch-mark
  "Touch a view by accessibilityIdentifier/Label (mark)"
  [mark]
  (query* [:UIView {:marked mark}]))

(defn scroll
  ([dir] (scroll [:UIScrollView] dir))
  ([q dir]
     (logging
      {:query q
       :extras dir
       :action "scroll"}
      (http/map-views q :scroll dir))))

(defn scroll-to-row
  "Scrolls UITableView corresponding to query q to number"
  ([num] (scroll-to-row [:UITableView] num))
  ([q num]
     (logging
      {:query q
       :extras num
       :action "scroll-to-row"}
      (http/map-views q :scrollToRow num))))


(defn pinch
  ([in_out] (events/playback (str "pinch_" (name in_out))))
  ([q in_out]
     (logging
      {:query q
       :extras in_out
       :action "pinch"}
      (events/playback (str "pinch_" (name in_out)) {:query q}))))

(defn exists?
  [q]
  (boolean (not-empty (query* q))))

(defn not-exists?
  [q]
  (not (exists? q)))

(defn mark-exists?
  [mark]
  (exists? [:UIView {:marked mark}]))





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
