(ns calabash-jvm.utils
  (:require [clojure.data.json :as json]
            [clojure.tools.logging :as log]
            [clj-logging-config.log4j :as l4j]
            [calabash-jvm.env :as env]
            [clojure.set :as cljset])

  (:use [slingshot.slingshot :only [try+ throw+]])

  (:import (org.apache.log4j
            Logger ConsoleAppender EnhancedPatternLayout Level
            LogManager AppenderSkeleton Appender Layout Hierarchy
            SimpleLayout WriterAppender FileAppender NDC MDC)
           (org.apache.log4j.spi
            RepositorySelector DefaultRepositorySelector RootLogger LoggingEvent)
           (java.io OutputStream Writer File)))



;;https://github.com/malcolmsparks/clj-logging-config/issues/13
;;Until pulled: https://github.com/malcolmsparks/clj-logging-config/pull/14
(defmacro with-logging-context [x & body]
  `(let [x# ~x
         ctx# (into {} (. ~MDC getContext))]
     (try
       (if (map? x#)
         (doall (map (fn [[k# v#]] (if-not (nil? v#) (. ~MDC put (name k#) v#))) x#))
         (. ~NDC push (str x#)))
       ~@body
       (finally
        (if (map? x#)
          (doall (map (fn [[k# v#]]
                        (. ~MDC remove (name k#))
                        (when-let [old# (get ctx# (name k#))]
                          (. ~MDC put (name k#) old#))) x#))
          (. ~NDC pop))))))


(defn mdc-context [] (MDC/getContext))
(defn mdc-context-get [key] (MDC/get (name key)))


(defmacro
  logging
  [spec body]
  `(let [espec# ~spec
         newkeys# (cljset/difference (set (map name (keys espec#)))
                                     (set (keys (mdc-context))))
         logified-spec# (into {} (map (fn [k#]
                                        [(keyword k#) (get espec# (keyword k#))])
                                      newkeys#))]
     (with-logging-context
       logified-spec#
       ~body)))


(defn with-timeout*
  [opts action]
  (let [opts (merge {:timeout 10 :message "Timeout"} opts)
        f (future-call action)
        timeout (* 1000 (:timeout opts))
        res (deref f timeout :calabash-jvm/timeout)]
    (try
      (if (= :calabash-jvm/timeout res)
        (throw+ (merge {:type :calabash-jvm/timeout} opts))
        res)
      (finally
       (future-cancel f)))))

(defmacro with-timeout [opts & body]
  `(let [f# (fn [] ~@body)]
     (with-timeout* ~opts f#)))

(defn file-or-nil
  [name]
  (let [f (clojure.java.io/file name)]
    (when (.exists f) f)))

(defn pwd
  "get current working directory"
  []
  (. System getProperty "user.dir"))
