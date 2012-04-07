(ns calabash-jvm.http
  (:require [http.async.client :as http]
            [clojure.data.json :as json]
            [clj-http.client :as client]
            [clojure.tools.logging :as lg]
            [clj-logging-config.log4j :as l4j]
            [calabash-jvm.env :as env]))


(defn request
  "Generic request method"
  [method route body]

  (let [body {:query query
              :operation {:method_name method-name
                          :arguments (or args [])}}
        response (method-name
                  client
                  (str env/ENDPOINT "/map")
                  :body (json/json-str body))]
    (lg/debug (json/json-str body))
    (http/await response)
    (let [res (json/read-json (http/string response))]
      (lg/debug res)
      (if (not= "SUCCESS" (:outcome res))
        (env/err body res)
        (:results res))))))

(defn rpc-map
  "TODO doc rpc-map"
  [client method-name query & args]
  (let [body {:query query
              :operation {:method_name method-name
                          :arguments (or args [])}}
        response (method-name
                  client
                  (str env/ENDPOINT "/map")
                  :body (json/json-str body))]
    (lg/debug (json/json-str body))
    (http/await response)
    (let [res (json/read-json (http/string response))]
      (lg/debug res)
      (if (not= "SUCCESS" (:outcome res))
        (env/err body res)
        (:results res)))))
