(ns calabash-jvm
  (:require [clojure.tools.logging :as lg]
            [clj-logging-config.log4j :as l4j]
            [calabash-jvm
             [env :as env]
             [http :as http]
             [events :as events]]))




;; Public API ;;

(def playback events/playback)
(def interpolate events/interpolate)
(def record-begin! events/record-begin!)
(def record-end! events/record-end!)



(defn query*
  "query views and optionally apply selectors to the results
   Tries hard to filter out non-visible views"
  [q & selectors]
  (apply http/map-views  q :query selectors))

(defn query-all*
  "query views (optionally applying selectors to results)
   Does not filter out non-visible views"
  [q & selectors]
  (apply http/map-views q :query_all selectors))


(defn touch*
  "touch the center of the view that results from performing query q.
   Options include offset..."
  ([q] (touch* q {}))
  ([q options]
     (playback "touch"
               (if q
                 (assoc options :query q)
                 options))))

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
     (http/map-views q :scroll dir)))

(defn scroll-to-row
  "Scrolls UITableView corresponding to query q to number"
  ([num] (scroll-to-row [:UITableView] num))
  ([q num]
      (http/map-views q :scrollToRow num)))




;;;; PUBLIC DSL ;;;;

(defn- dsl-op
  [key val]
  {::_calabash-type key
   key val})

(defn index
  "construct an index query"
  [i]
  (dsl-op :index i))

(defn css
  "construct a css query for web views"
  [css]
  (dsl-op :css css))

(defn xpath
  "construct an xpath query for web views"
  [xpath]
  (dsl-op :xpath xpath))
