(ns calabash-jvm.env
  (:require [clojure.tools.logging :as lg]))

(defn getenv [str] (System/getenv str))

(def ^:dynamic *os* (or (getenv "OS") "ios5"))
(def ^:dynamic *idiom* (or (getenv "DEVICE") "iphone"))
(def current-rotation (atom :down))

(defn get-current-rotation
  "Returns the current-rotation value"
  []
  @current-rotation)

(defn set-current-rotation
  "Sets the current-rotation value"
  [dir]
  (swap! current-rotation (fn [n] dir)))

(defn new-current-rotation
  "Called by rotate function to set the correct current-rotation."
  [dir]
  (let [curr-rot (get-current-rotation)]
    (condp = curr-rot
      :up (set-current-rotation dir)
      :down (if (= :left dir)
              (set-current-rotation :right)
              (set-current-rotation :left))
      :right (if (= curr-rot dir)
               (set-current-rotation :down)
               (set-current-rotation :up))
      :left (if (= :left dir)
              (set-current-rotation :down)
              (set-current-rotation :up)))))

(def ^:dynamic *endpoint*
  (or (getenv "DEVICE_ENDPOINT") "http://localhost:37265"))

(defn resource
  [path] (str *endpoint* "/" path))
