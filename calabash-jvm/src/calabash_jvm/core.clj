(ns calabash-jvm.core
  (:require [http.async.client :as http]
            [clojure.data.json :as json]
            [clojure.tools.logging :as lg]
            [clj-logging-config.log4j :as l4j]
            [calabash-jvm.env :as env]))


(def client (http/create-client))


(defn rpc-map
  "TODO doc rpc-map"
  [method-name query & args]
  (let [body {:query query
              :operation {:method_name method-name
                          :arguments (or args [])}}
        response (http/POST
                  *client*
                  (str ENDPOINT "/map")
                  :body (json/json-str body))]
    (lg/debug (json/json-str body))
    (http/await response)
    (let [res (json/read-json (http/string response))]
      (lg/debug res)
      (if (not= "SUCCESS" (:outcome res))
        (err body res)
        (:results res)))))


;; The key is to start swank from emacs as the inferior lisp process instead of calling lein swank from the shell. One way to do this is to use elein (the command is M-x elein-swank). Then you can either inspect the output in the inferior lisp buffer (which is called *elein-swank* in the example of using elein), or execute slime-redirect-inferior-output and have the output inline in the repl. Clojure.contrib.logging is a useful tool for sending log output.
