(ns calabash-jvm.env
  (:require [clojure.tools.logging :as lg]))

(defn getenv [str] (System/getenv str))

(def ^:dynamic *os* (or (getenv "OS") "ios5"))
(def ^:dynamic *idiom* (or (getenv "DEVICE") "iphone"))

(def ^:dynamic *endpoint*
  (or (getenv "DEVICE_ENDPOINT") "http://localhost:37265"))

(defn resource
  [path] (str *endpoint* "/" path))
