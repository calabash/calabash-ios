(ns calabash-jvm.events
  (:require [clojure.data.json :as json]
            [clj-http.client :as client]
            [clj-http.conn-mgr :as mgr]
            [clojure.tools.logging :as lg]
            [clj-logging-config.log4j :as l4j]
            [calabash-jvm.env :as env]
            [calabash-jvm.http :as http]
            [calabash-jvm.utils :as utils]
            [clojure.java.shell :as sh])
  (:import [java.io File]))


(defn slurp-first-match
  "finds and reads resource with filename
   in one of the dirs directories, or on classpath"
  [filename & dirs]
  (let [matches
        (->> (cons (utils/pwd) dirs) ;;search pwd first
            (map #(str % File/separator filename))
            (filter utils/file-or-nil))
        best-match (first matches)]
    (when-let [data (or best-match
                        (clojure.java.io/resource filename))]
      (slurp data))))


(defn event-data
  "Loads an event file based on current environment (calabash-jvm.env/*os*, *idiom*)"
  [filename]
  (let [filename (if (.endsWith filename ".base64")
                   filename
                   (str filename "_" env/*os* "_" env/*idiom* ".base64"))

        event-dir (or (env/getenv "PLAYBACK_DIR")
                      (str (utils/pwd) "playback"))]
    (slurp-first-match filename "features" event-dir)))


(defn record-begin!
  []
  (http/req {:method :post
             :path "record"
             :check-json? false} {:action :start}))

(defn record-end!
  [file]
  (let [rsp (http/req {:method :post
                       :path "record"
                       :check-json? false} {:action :stop})
        f (spit "_recording.plist" rsp)
        filename (str file "_" env/*os* "_" env/*idiom* ".base64")]
    (sh/sh "/usr/bin/plutil" "-convert" "binary1" "-o" "_recording_binary.plist" "_recording.plist")
    (sh/sh "openssl" "base64" "-in" "_recording_binary.plist" "-out" filename)
    (sh/sh "rm" "_recording.plist" "_recording_binary.plist")

    filename))


(defn- event-action
  [recname options route]
  (if-let [data (event-data recname)]
    (http/req {:method :post
               :path route
               :as :json}
              (merge {:events data} options))))

(defn playback
  "plays back a pre-recorded sequence of events"
  ([recname] (playback recname {}))
  ([recname options]
     (event-action recname options "play")))

(defn interpolate
  "TBD"
  ([recname] (interpolate recname {}))
  ([recname options]
     (event-action recname options "interpolate")))
