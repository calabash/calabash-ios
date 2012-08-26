(ns calabash-jvm.wait
  (:require [calabash-jvm
             [http :as http]
             [core :as core]
             [utils :as utils]]))


(defn do-until
  [pred action]
  (loop []
    (if (Thread/interrupted)
      (.interrupt (Thread/currentThread))
      (let [res (action)]
        (if (pred res)
          res
          (recur))))))

(defn wait_for*
  "Waits for a condition to occur. Options
      :timeout (10) number of seconds to wait at most
      :retry_frequency (0.3) number of seconds to sleep between polls
      :post_timeout (0.1) number of seconds to wait after the condition occurs
      :timeout_message (Timed out waiting) message to throw if condition does not occur within :timeout"
  ([action] (wait_for* {} action))
  ([opts action]
      (let [opts (merge {:timeout 10
                         :retry_frequency 0.2
                         :post_timeout 0.1
                         :timeout_message "Timed out waiting..."}
                        opts)
            sleep! (fn [] (Thread/sleep (* 1000 (:retry_frequency opts))))]
        (utils/with-timeout opts
          (do-until true?
                    (fn [] (if-let [res (action)]
                            res
                            (sleep!)))))
        (when (> 0 (:post_timeout opts))
          (Thread/sleep (* 1000 (:post_timeout opts)))))))

(defmacro wait_for
  ([body] `(wait_for {} ~body))
  ([opts & body]
     `(wait_for* ~opts (fn [] ~@body))))


(defn wait_for_exists
  ([qs] (wait_for_exists qs {}))
  ([qs opts]
      (let [opts (merge {:timeout_message (str "Timed out waiting for" qs)}
                        opts)]
        (wait_for opts (every? true? (map core/exists? qs))))))
