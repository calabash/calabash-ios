(ns calabash-jvm
  (:require [clojure.tools.logging :as log]
            [clj-logging-config.log4j :as l4j]
            [calabash-jvm
             [core :as core]
             [keyboard :as keyboard]
             [utils :as utils]
             [env :as env]
             [http :as http]
             [wait :as wait]
             [events :as events]])
  (:use [calabash-jvm.utils :only [logging]]))



(l4j/set-loggers!

    ["org.apache.http"]
    {:level :info}

    ["calabash-jvm"]
    {:level :info
     :pattern "%p %m (query=%X{query}, action=%X{action}, :extras=%X{extras}) %n"})


;; Public API ;;

(defn query*
  "query views and optionally apply selectors to the results
   Tries hard to filter out non-visible views"
  [q & selectors]
  (apply core/query* q selectors))

(defn flash
  [q & selectors]
  "Example : (flash [:UIButton {:marked \"accessiblity-label\"}])"
  (logging
   {:query q
    :extras selectors
    :action "query*"}
   (apply http/map-views  q :flash selectors)))

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
  (touch* [:UIView {:marked mark}]))

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
     (if q
       (core/pinch q in-out)
       (pinch in-out))))


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


(defn screenshot
  "Takes a screenshot of the current view (keyword args :prefix and :name determine output file)"
  [& args]
  (apply core/screenshot args))

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



(defprotocol Keywordize
  (kw [this] "Keyworded version of this")
  (st [this] "Stringified version of this"))

(extend-protocol Keywordize
  nil
  (kw [this] nil)
  (st [this] nil)

  clojure.lang.Keyword
  (kw [this] this)
  (st [this] (name this))

  String
  (kw [this] (keyword this))
  (st [this] this)

  java.util.List
  (kw [this] (map kw this))
  (st [this] (map st this))

  java.util.Map
  (kw [this] (clojure.walk/keywordize-keys this))
  (st [this] (clojure.walk/stringify-keys this)))


;; interop

(gen-class
 :name calabash_jvm.API
 :main true
 :methods [
           ^:static [index [Integer] java.util.Map]
           ^:static [xpath [String] java.util.Map]
           ^:static [css [String] java.util.Map]

           ^:static [query [java.util.List java.util.List] java.util.List]
           ^:static [queryq [String String] java.util.List]
           ^:static [queryAll [java.util.List java.util.List] java.util.List]
           ^:static [queryqAll [String String] java.util.List]
           ^:static [q     [String] java.util.List]
           ^:static [touch [java.util.List java.util.Map] java.util.Map]
           ^:static [touchq [String String] java.util.Map]
           ^:static [touchAt [Integer Integer] java.util.Map]
           ^:static [touchMark [String] java.util.Map]
           ^:static [scroll [java.util.List String] java.util.List]
           ^:static [scrollToRow [java.util.List Integer] java.util.List]
           ^:static [pinch [java.util.List String] java.util.Map]
           ^:static [enterChar [String] java.util.Map]
           ^:static [enterText [String] java.util.Map]
           ^:static [done [] java.util.Map]
           ^:static [recordBegin [] String]
           ^:static [recordEnd [String] String]
           ^:static [playbackEvents [String java.util.Map] java.util.Map]
           ^:static [interpolateEvents [String java.util.Map] java.util.Map]
           ^:static [setHttpLogLevel [String] void]
           ^:static [setCalabashLogLevel [String] void]
           ^:static [existsq [String] boolean]
           ^:static [exists [java.util.List] boolean]
           ^:static [waitForExistsq [String String] void]
           ^:static [waitForExists [java.util.List java.util.Map] void]
           ^:static [waitForAllExistq [String String] void]
           ^:static [waitForAllExist [java.util.List java.util.Map] void]
           ^:static [screenshot [java.util.Map] String]

           ])

(defn- -index
  [i]
  (index i))
(defn- -css
  [s]
  (css s))

(defn- -xpath
  [s]
  (xpath s))

(defn- -q [s]
  (->> (read-string s)
       (clojure.walk/postwalk-replace
        '{index calabash-jvm/index
          css   calabash-jvm/css
          xpath calabash-jvm/xpath})
       eval))

(defn- -query [x args] (st (apply query* x (kw args))))

(defn- -queryq [qs os]
  (st (apply query* (-q qs) (-q os))))

(defn- -queryqAll
  [qs os]
  (st (apply query-all* (-q qs) (-q os))))

(defn- -touchq
  [qs os]
  (st (touch* (-q qs) (-q os))))

(defn- -queryAll [x args]  (st (apply query-all* x (kw args))))


(defn- -touch [q opt] (st (touch* q (kw opt))))
(defn- -touchAt [x y] (st (touch-point x y)))
(defn- -touchMark [mark] (st (touch-mark mark)))
(defn- -scroll [q dir] (st (scroll q (keyword dir))))
(defn- -scrollToRow [q n] (st (scroll-to-row q n)))
(defn- -pinch [q dir] (st (pinch q (keyword dir))))
(defn- -enterChar [s] (st (enter-char s)))
(defn- -enterText [s] (st (enter-text s)))
(def ^:private -done done)
(def ^:private -recordBegin record-begin!)
(def ^:private -recordEnd record-end!)
(defn- -playbackEvents [name opts] (playback name (kw opts)))
(defn- -interpolateEvents [name opts] (interpolate name (kw opts)))
(defn- -setHttpLogLevel [name] (set-http-log-level! (keyword name)))
(defn- -setCalabashLogLevel [name] (set-calabash-log-level! (keyword name)))


(defn- -existsq [qs] (core/exists? (-q qs)))
(defn- -exists [q] (core/exists? q))

(defn- -waitForExistsq
  [qs opts]
  (wait/wait_for_exists [(-q  qs)] (-q opts)))

(defn- -waitForExists
  [qs opts]
  (wait/wait_for_exists  [qs] opts))


(defn- -waitForAllExistq
  [qs opts]
  (wait/wait_for_exists (-q  qs) (-q opts)))


(defn- -waitForAllExist
  [qs opts]
  (wait/wait_for_exists  qs opts))

(defn- -screenshot
  [opts]
  (apply screenshot (flatten (seq (or (kw opts) {})))))


(defn -main [& args]
  (require 'calabash-jvm)
  (when (< (count args) 1)
    (println "Usage java -cp target/calabash-jvm-[VERSION]-standalone.jar calabash_jvm.API calabash_jvm.API [query] (selectors)")
    (System/exit 1))
  (let [ds (-q (first args))
        args (rest args)]
    (prn "Running Query: " ds args)
    (prn (apply query* ds args))))
