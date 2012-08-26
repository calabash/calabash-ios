(ns calabash-jvm
  (:require [clojure.tools.logging :as log]
            [clj-logging-config.log4j :as l4j]
            [calabash-jvm
             [core :as core]
             [keyboard :as keyboard]
             [utils :as utils]
             [env :as env]
             [http :as http]
             [events :as events]])
  (:use [calabash-jvm.utils :only [logging]]))



(l4j/set-loggers!

    ["org.apache.http"]
    {:level :info}

    ["calabash-jvm"]
    {:level :debug
     :pattern "%p %m (query=%X{query}, action=%X{action}, :extras=%X{extras}) %n"})


;; Public API ;;

(defn query*
  "query views and optionally apply selectors to the results
   Tries hard to filter out non-visible views"
  [q & selectors]
  (apply core/query* q selectors))

(defn query-all*
  "query views (optionally applying selectors to results)
   Does not filter out non-visible views"
  [q & selectors]
  (apply core/query-all* q selectors))

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
  "Scrolls a scroll view in direction dir (:up, :down, :left, :right)
   May specify a query (q) determining what to scroll. Default is [:UIScrollView]"
  ([dir] (scroll [:UIScrollView] dir))
  ([q dir]
     (core/scroll q dir)))

(defn scroll-to-row
  "Scrolls UITableView corresponding to query q to number num.  Default is [:UITableView]"
  ([num] (scroll-to-row [:UITableView] num))
  ([q num]
     (core/scroll-to-row q num)))


(defn pinch
  "Pinch :in or :out (in-out). May specify query."
  ([in-out] (events/playback (str "pinch_" (name in-out))))
  ([q in-out]
     (core/pinch q in-out)))


(defn enter-char
  "Enters a single character (char) using the iOS keyboard.
   The character must be visible. char must be a string of length one or one of
   'Dictation'
   'Shift'
   'Delete'
   'International'
   'More'
   'Return'"
  [char]
  (keyboard/enter-char char))

(defn enter-text
  "Enters several characters (text) using the iOS keyboard.
  Tries to find the chars in the keyplanes of the keyboard."
  [text]
  (keyboard/enter-text text))

(defn done
  "Touches return/done/search on keyboard"
  []  (enter-char "Return"))

(defn search "Touches return/done/search on keyboard" [] (done))


(defn record-begin!
  "Begins recording touch events"
  []
  (events/record-begin!))

(defn record-end!
  "Finishes recording touch events. The recorded events as saved using name param as name."
  [name]
  (events/record-end! name))

(defn playback
  "Plays back a pre-recorded sequence of events with options."
  ([recname] (events/playback recname))
  ([recname options]
     (events/playback recname options)))

(defn interpolate
  "TBD"
  ([recname] (events/interpolate recname))
  ([recname options]
     (events/interpolate recname options)))





(defn set-http-log-level!
  [level] (l4j/set-logger-level! "org.apache.http" level))

(defn set-calabash-log-level!
  [level] (l4j/set-logger-level! "calabash-jvm" level))

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



;; interop

(gen-class
 :name calabash_jvm.API
 :main true
 :methods [^:static [query [java.util.List java.util.List] java.util.List]
           ^:static [queryq [String java.util.List] java.util.List]
           ^:static [q     [String] java.util.List]])

(defn- -query [x & args] (apply query* x args))


(defn- -q [s] (eval (read-string s)))


(defn- -queryq [x ss]
  (let [ds (-q x)]
    (apply query* ds ss)))

(defn -main [& args]
  (when (< (count args) 1)
    (println "Usage java -cp target/calabash-jvm-[VERSION]-standalone.jar calabash_jvm.API calabash_jvm.API [query] (selectors)")
    (System/exit 1))
  (let [ds (read-string (first args))
        args (rest args)]
    (if (vector? ds)
      (do
        (prn "Running Query: " ds "(" (class ds) ")")
        (prn (apply query* (eval ds) args)))
      (eval ds))))
