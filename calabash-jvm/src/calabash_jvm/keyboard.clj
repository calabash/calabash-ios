(ns calabash-jvm.keyboard
  (:require [clojure.data.json :as json]
            [clj-http.client :as client]
            [clj-http.conn-mgr :as mgr]
            [clojure.tools.logging :as log]
            [clj-logging-config.log4j :as l4j]
            [calabash-jvm  [env :as env]
             [http :as http]
             [events :as events]
             [core :as core]])
  (:use [slingshot.slingshot :only [try+ throw+]]
        [calabash-jvm.utils :only [logging]]))

(def keyplane-names
  {:small_letters "small-letters",
   :capital_letters "capital-letters",
   :numbers_and_punctuation "numbers-and-punctuation",
   :first_alternate "first-alternate",
   :numbers_and_punctuation_alternate "numbers-and-punctuation-alternate"})

(def known-keyplanes (set (vals keyplane-names)))

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
  (logging
   {:extras char
    :action "enter-char"}
   (http/req {:method :post
              :path "keyboard"
              :as :json}
             {:key char
              :events (events/event-data "touch")})))

(defn- do-keyplane
  [kbtree-action keyplane-action]
  (let [kbd (first (core/query* [:UIKBKeyplaneView] :keyplane))]
    (cond
     (empty? kbd) (throw+ {:type ::missing :message "No visible keyboard"})
     (re-seq #"<UIKBTree" kbd) (kbtree-action)
     (re-seq #"<UIKBKeyplane" kbd) (keyplane-action))))


(defn current-keyplane
  []
  (let [res
        (do-keyplane
         #(core/query* [:UIKBKeyplaneView] :keyplane :componentName)
         #(core/query* [:UIKBKeyplaneView] :keyplane :name))]
    (.toLowerCase (first res))))

(defn keyboard-properties
  []
  (first
   (do-keyplane
    #(core/query* [:UIKBKeyplaneView] :keyplane :properties)
    #(core/query* [:UIKBKeyplaneView] :keyplane :attributes :dict))))

(declare search-keyplanes-and-enter)

(defn- search-next-keyplanes
  [chr visited]
  (loop [keys ["shift" "more"]]
    (if (empty? keys)
      false
      (let [key (first keys)
            alt-key (keyword (str key "-alternate"))
            plane (get (keyboard-properties) alt-key)]
            (if (or (visited plane) (not (known-keyplanes plane)))
          (recur (rest keys))
          (let [switch-plane!
                (fn [] (enter-char (clojure.string/capitalize key)))]
            (switch-plane!)

            ;;Recursive search for key
            (if (search-keyplanes-and-enter chr visited)
              true ;;done
              (do ;; not found, restore keyplane and keep searching
                (switch-plane!)
                (recur (rest keys))))))))))

(defn search-keyplanes-and-enter
  ([chr] (search-keyplanes-and-enter chr (hash-set)))
  ([chr visited]
     (try+
      (boolean (enter-char chr))
      (catch [:type :calabash-jvm/protocol-error] _
        (search-next-keyplanes chr (conj visited (current-keyplane)))))))


(defn enter-text
  [text]
  (logging
   {:extras text
    :action "enter-text"}
   (if (empty? (core/query* [:UIKBKeyplaneView]))
     (throw+ {:type ::missing :message "No visible keyboard"})
     (do
       (log/debug "Enter text" text)
       (doseq [k text]
         (search-keyplanes-and-enter (str k)))))))

;; (
;;     res = http({:method => :post, :path => 'keyboard'},
;;                    {:key => chr, :events => load_playback_data("touch_done")})
;;         res = JSON.parse(res)
;;         if res['outcome'] != 'SUCCESS'
;;           msg = "Keyboard enter failed failed because: #{res['reason']}\n#{res['details']}"
;;           if should_screenshot
;;             screenshot_and_raise msg
;;           else
;;             raise msg
;;           end
;;         end
;;         res['results'])
